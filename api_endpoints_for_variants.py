"""
🔥 API ENDPOINTS for Product Variants

Create REST API endpoints for creating and managing products with variants
"""

from rest_framework import serializers, viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from shop.models import Product, ProductVariant, VariantAttribute, Attribute, NewAttributeValue


# ========================================
# SERIALIZERS
# ========================================

class VariantAttributeSerializer(serializers.ModelSerializer):
    """Serializer for variant attributes"""
    attribute_name = serializers.CharField(source='attribute_value.attribute.name', read_only=True)
    attribute_key = serializers.CharField(source='attribute_value.attribute.key', read_only=True)
    value = serializers.CharField(source='attribute_value.value', read_only=True)
    
    class Meta:
        model = VariantAttribute
        fields = ['attribute_name', 'attribute_key', 'value']


class ProductVariantSerializer(serializers.ModelSerializer):
    """Serializer for product variants"""
    attributes = VariantAttributeSerializer(source='variant_attributes', many=True, read_only=True)
    formatted_price = serializers.CharField(source='get_formatted_price', read_only=True)
    is_in_stock = serializers.BooleanField(read_only=True)
    is_low_stock = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = ProductVariant
        fields = [
            'id', 'sku', 'variant_name', 'price_toman', 'price_usd',
            'stock_quantity', 'is_active', 'is_default', 'attributes',
            'formatted_price', 'is_in_stock', 'is_low_stock'
        ]


class ProductWithVariantsSerializer(serializers.ModelSerializer):
    """Serializer for products with their variants"""
    variants = ProductVariantSerializer(many=True, read_only=True)
    variants_count = serializers.IntegerField(source='get_variants().count', read_only=True)
    total_stock = serializers.IntegerField(source='get_total_stock', read_only=True)
    price_range = serializers.CharField(source='get_price_range', read_only=True)
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'slug', 'description', 'category', 'brand',
            'is_active', 'variants', 'variants_count', 'total_stock', 'price_range'
        ]


# ========================================
# CREATE PRODUCT WITH VARIANTS SERIALIZER
# ========================================

class CreateVariantSerializer(serializers.Serializer):
    """Serializer for creating a single variant"""
    sku = serializers.CharField(max_length=100)
    variant_name = serializers.CharField(max_length=200, required=False)
    price_toman = serializers.DecimalField(max_digits=12, decimal_places=0)
    price_usd = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    stock_quantity = serializers.IntegerField(min_value=0)
    is_default = serializers.BooleanField(default=False)
    attributes = serializers.DictField(child=serializers.CharField())


class CreateProductWithVariantsSerializer(serializers.Serializer):
    """Serializer for creating a product with multiple variants"""
    
    # Product data
    name = serializers.CharField(max_length=200)
    slug = serializers.SlugField(max_length=200)
    description = serializers.CharField(required=False, allow_blank=True)
    category_id = serializers.IntegerField()
    brand = serializers.CharField(max_length=100, required=False, allow_blank=True)
    is_active = serializers.BooleanField(default=True)
    
    # Variants data
    variants = CreateVariantSerializer(many=True)
    
    def validate_variants(self, variants):
        """Validate variants data"""
        if not variants:
            raise serializers.ValidationError("حداقل یک ترکیب باید تعریف شود")
        
        # Check for duplicate SKUs
        skus = [v['sku'] for v in variants]
        if len(skus) != len(set(skus)):
            raise serializers.ValidationError("کدهای محصول نمی‌توانند تکراری باشند")
        
        # Ensure exactly one default variant
        default_count = sum(1 for v in variants if v.get('is_default', False))
        if default_count != 1:
            raise serializers.ValidationError("دقیقاً یک ترکیب باید به عنوان پیش‌فرض تعریف شود")
        
        return variants
    
    def create(self, validated_data):
        """Create product with variants"""
        variants_data = validated_data.pop('variants')
        
        with transaction.atomic():
            # Create product
            product = Product.objects.create(**validated_data)
            
            # Create variants
            for variant_data in variants_data:
                attributes_data = variant_data.pop('attributes')
                
                variant = ProductVariant.objects.create(
                    product=product,
                    **variant_data
                )
                
                # Create variant attributes
                for attr_key, attr_value in attributes_data.items():
                    try:
                        attribute = Attribute.objects.get(key=attr_key)
                        attribute_value = NewAttributeValue.objects.get(
                            attribute=attribute, 
                            value=attr_value
                        )
                        VariantAttribute.objects.create(
                            variant=variant,
                            attribute_value=attribute_value
                        )
                    except (Attribute.DoesNotExist, NewAttributeValue.DoesNotExist):
                        raise serializers.ValidationError(
                            f"ویژگی '{attr_key}' با مقدار '{attr_value}' یافت نشد"
                        )
            
            return product


# ========================================
# API VIEWS
# ========================================

class ProductVariantViewSet(viewsets.ModelViewSet):
    """ViewSet for managing product variants"""
    queryset = ProductVariant.objects.all()
    serializer_class = ProductVariantSerializer
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by product
        product_id = self.request.query_params.get('product_id')
        if product_id:
            queryset = queryset.filter(product_id=product_id)
        
        # Filter by attributes
        for key, value in self.request.query_params.items():
            if key.startswith('attr_'):
                attr_key = key[5:]  # Remove 'attr_' prefix
                queryset = queryset.filter(
                    variant_attributes__attribute_value__attribute__key=attr_key,
                    variant_attributes__attribute_value__value=value
                )
        
        return queryset.distinct()
    
    @action(detail=True, methods=['post'])
    def update_stock(self, request, pk=None):
        """Update stock quantity for a variant"""
        variant = self.get_object()
        quantity = request.data.get('quantity')
        
        if quantity is None:
            return Response(
                {'error': 'مقدار موجودی الزامی است'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            quantity = int(quantity)
            if quantity < 0:
                return Response(
                    {'error': 'موجودی نمی‌تواند منفی باشد'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            variant.stock_quantity = quantity
            variant.save()
            
            return Response({
                'message': 'موجودی بروزرسانی شد',
                'new_stock': variant.stock_quantity
            })
        
        except ValueError:
            return Response(
                {'error': 'مقدار موجودی باید عدد باشد'}, 
                status=status.HTTP_400_BAD_REQUEST
            )


class ProductWithVariantsViewSet(viewsets.ModelViewSet):
    """ViewSet for managing products with variants"""
    queryset = Product.objects.all()
    serializer_class = ProductWithVariantsSerializer
    
    def get_queryset(self):
        return super().get_queryset().prefetch_related(
            'variants__variant_attributes__attribute_value__attribute'
        )
    
    @action(detail=False, methods=['post'])
    def create_with_variants(self, request):
        """Create a product with multiple variants"""
        serializer = CreateProductWithVariantsSerializer(data=request.data)
        
        if serializer.is_valid():
            product = serializer.save()
            return Response({
                'message': 'محصول با موفقیت ایجاد شد',
                'product_id': product.id,
                'variants_count': product.variants.count()
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def add_variant(self, request, pk=None):
        """Add a new variant to existing product"""
        product = self.get_object()
        
        serializer = CreateVariantSerializer(data=request.data)
        if serializer.is_valid():
            variant_data = serializer.validated_data
            attributes_data = variant_data.pop('attributes')
            
            with transaction.atomic():
                variant = ProductVariant.objects.create(
                    product=product,
                    **variant_data
                )
                
                # Add attributes
                for attr_key, attr_value in attributes_data.items():
                    try:
                        attribute = Attribute.objects.get(key=attr_key)
                        attribute_value = NewAttributeValue.objects.get(
                            attribute=attribute, 
                            value=attr_value
                        )
                        VariantAttribute.objects.create(
                            variant=variant,
                            attribute_value=attribute_value
                        )
                    except (Attribute.DoesNotExist, NewAttributeValue.DoesNotExist):
                        return Response({
                            'error': f"ویژگی '{attr_key}' با مقدار '{attr_value}' یافت نشد"
                        }, status=status.HTTP_400_BAD_REQUEST)
            
            return Response({
                'message': 'ترکیب جدید اضافه شد',
                'variant_id': variant.id,
                'sku': variant.sku
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['get'])
    def available_attributes(self, request, pk=None):
        """Get available attributes for this product"""
        product = self.get_object()
        attributes = product.get_available_attributes()
        
        result = []
        for attr in attributes:
            values = NewAttributeValue.objects.filter(
                attribute=attr,
                variant_attributes__variant__product=product
            ).distinct().values_list('value', flat=True)
            
            result.append({
                'key': attr.key,
                'name': attr.name,
                'values': list(values)
            })
        
        return Response(result)


# ========================================
# URL CONFIGURATION
# ========================================

"""
Add to your urls.py:

from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'products', views.ProductWithVariantsViewSet)
router.register(r'variants', views.ProductVariantViewSet)

urlpatterns = [
    path('api/', include(router.urls)),
]
"""


# ========================================
# API USAGE EXAMPLES
# ========================================

def api_usage_examples():
    """
    🔥 API USAGE EXAMPLES
    """
    
    print("🔥 API ENDPOINTS USAGE EXAMPLES:")
    print()
    
    # Example 1: Create product with variants
    create_product_example = {
        "name": "iPhone 15 Pro",
        "slug": "iphone-15-pro",
        "description": "Latest iPhone with Pro features",
        "category_id": 2,
        "brand": "Apple",
        "is_active": True,
        "variants": [
            {
                "sku": "IPHONE-BLUE-128GB",
                "variant_name": "Blue - 128GB",
                "price_toman": 35000000,
                "stock_quantity": 15,
                "is_default": True,
                "attributes": {
                    "color": "Blue",
                    "storage": "128GB"
                }
            },
            {
                "sku": "IPHONE-BLUE-256GB",
                "variant_name": "Blue - 256GB",
                "price_toman": 38000000,
                "stock_quantity": 12,
                "is_default": False,
                "attributes": {
                    "color": "Blue",
                    "storage": "256GB"
                }
            },
            {
                "sku": "IPHONE-BLACK-128GB",
                "variant_name": "Black - 128GB",
                "price_toman": 35500000,
                "stock_quantity": 10,
                "is_default": False,
                "attributes": {
                    "color": "Black",
                    "storage": "128GB"
                }
            }
        ]
    }
    
    print("1️⃣ CREATE PRODUCT WITH VARIANTS:")
    print("POST /api/products/create_with_variants/")
    print("Body:", create_product_example)
    print()
    
    # Example 2: Add variant to existing product
    add_variant_example = {
        "sku": "IPHONE-WHITE-512GB",
        "variant_name": "White - 512GB",
        "price_toman": 42000000,
        "stock_quantity": 5,
        "is_default": False,
        "attributes": {
            "color": "White",
            "storage": "512GB"
        }
    }
    
    print("2️⃣ ADD VARIANT TO EXISTING PRODUCT:")
    print("POST /api/products/{product_id}/add_variant/")
    print("Body:", add_variant_example)
    print()
    
    # Example 3: Get products with variants
    print("3️⃣ GET PRODUCTS WITH VARIANTS:")
    print("GET /api/products/")
    print("Response includes all variants for each product")
    print()
    
    # Example 4: Filter variants by attributes
    print("4️⃣ FILTER VARIANTS BY ATTRIBUTES:")
    print("GET /api/variants/?attr_color=Blue&attr_storage=128GB")
    print("Returns all Blue 128GB variants across all products")
    print()
    
    # Example 5: Update stock
    print("5️⃣ UPDATE VARIANT STOCK:")
    print("POST /api/variants/{variant_id}/update_stock/")
    print("Body: {'quantity': 25}")
    print()
    
    return {
        'create_product': create_product_example,
        'add_variant': add_variant_example
    }


# ========================================
# JAVASCRIPT FRONTEND EXAMPLES
# ========================================

javascript_examples = """
🔥 JAVASCRIPT USAGE EXAMPLES:

// 1. Create product with variants
async function createProductWithVariants(productData) {
    const response = await fetch('/api/products/create_with_variants/', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': getCookie('csrftoken')
        },
        body: JSON.stringify(productData)
    });
    
    const result = await response.json();
    if (response.ok) {
        console.log('Product created:', result);
    } else {
        console.error('Error:', result);
    }
}

// 2. Get product variants
async function getProductVariants(productId) {
    const response = await fetch(`/api/variants/?product_id=${productId}`);
    const variants = await response.json();
    return variants.results;
}

// 3. Filter variants by attributes
async function filterVariants(attributes) {
    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(attributes)) {
        params.append(`attr_${key}`, value);
    }
    
    const response = await fetch(`/api/variants/?${params}`);
    const variants = await response.json();
    return variants.results;
}

// 4. Update variant stock
async function updateVariantStock(variantId, quantity) {
    const response = await fetch(`/api/variants/${variantId}/update_stock/`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': getCookie('csrftoken')
        },
        body: JSON.stringify({ quantity })
    });
    
    return await response.json();
}

// Example usage:
const productData = {
    name: "Test Product",
    slug: "test-product",
    category_id: 1,
    variants: [
        {
            sku: "TEST-RED-M",
            price_toman: 250000,
            stock_quantity: 50,
            is_default: true,
            attributes: { color: "Red", size: "M" }
        }
    ]
};

createProductWithVariants(productData);
"""

print(javascript_examples)


if __name__ == "__main__":
    api_usage_examples()
