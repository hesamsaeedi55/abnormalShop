from rest_framework import serializers
from django.db import models
from shop.models import Product, ProductVariant, ProductImage, Category, Tag
from suppliers.models import Supplier, Store


class SupplierProductSerializer(serializers.ModelSerializer):
    """Serializer for products in supplier context"""
    category_name = serializers.CharField(source='category.name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    variants_count = serializers.SerializerMethodField()
    images_count = serializers.SerializerMethodField()
    total_stock = serializers.SerializerMethodField()
    formatted_price_toman = serializers.SerializerMethodField()
    formatted_price_usd = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price_toman', 'price_usd',
            'model', 'sku', 'weight', 'dimensions', 'warranty',
            'stock_quantity', 'is_active', 'is_new_arrival', 'is_in_special_offers',
            'created_at', 'category', 'category_name', 'supplier', 'supplier_name',
            'variants_count', 'images_count', 'total_stock',
            'formatted_price_toman', 'formatted_price_usd',
            'reduced_price_toman', 'discount_percentage'
        ]
        read_only_fields = ['id', 'created_at', 'supplier']
    
    def get_variants_count(self, obj):
        return obj.variants.count()
    
    def get_images_count(self, obj):
        return obj.images.count()
    
    def get_total_stock(self, obj):
        # Calculate total stock including variants
        variant_stock = obj.variants.aggregate(total=models.Sum('stock_quantity'))['total'] or 0
        return obj.stock_quantity + variant_stock
    
    def get_formatted_price_toman(self, obj):
        return obj.get_formatted_toman_price()
    
    def get_formatted_price_usd(self, obj):
        return obj.get_formatted_usd_price()


class SupplierProductCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating products in supplier context"""
    
    class Meta:
        model = Product
        fields = [
            'name', 'description', 'price_toman', 'price_usd',
            'model', 'sku', 'weight', 'dimensions', 'warranty',
            'stock_quantity', 'is_active', 'is_new_arrival', 'is_in_special_offers',
            'category', 'tags', 'reduced_price_toman', 'discount_percentage'
        ]
    
    def validate_sku(self, value):
        """Ensure SKU is unique within the supplier"""
        if value:
            supplier = self.context.get('supplier')
            if supplier and Product.objects.filter(supplier=supplier, sku=value).exists():
                raise serializers.ValidationError('SKU must be unique within your supplier')
        return value
    
    def create(self, validated_data):
        tags = validated_data.pop('tags', [])
        product = Product.objects.create(**validated_data)
        product.tags.set(tags)
        return product


class SupplierProductVariantSerializer(serializers.ModelSerializer):
    """Serializer for product variants in supplier context"""
    product_name = serializers.CharField(source='product.name', read_only=True)
    formatted_price_toman = serializers.SerializerMethodField()
    formatted_price_usd = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductVariant
        fields = [
            'id', 'product', 'product_name', 'sku', 'attributes',
            'price_toman', 'price_usd', 'stock_quantity', 'is_active',
            'is_default', 'isDistinctive', 'created_at',
            'formatted_price_toman', 'formatted_price_usd'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_formatted_price_toman(self, obj):
        if obj.price_toman:
            return f"{obj.price_toman:,.0f} تومان"
        return "قیمت تعیین نشده"
    
    def get_formatted_price_usd(self, obj):
        if obj.price_usd:
            return f"${obj.price_usd:,.2f}"
        return "قیمت دلاری تعیین نشده"


class SupplierProductVariantCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating product variants in supplier context"""
    
    class Meta:
        model = ProductVariant
        fields = [
            'product', 'sku', 'attributes', 'price_toman', 'price_usd',
            'stock_quantity', 'is_active', 'is_default', 'isDistinctive'
        ]
    
    def validate_sku(self, value):
        """Ensure SKU is unique"""
        if ProductVariant.objects.filter(sku=value).exists():
            raise serializers.ValidationError('SKU must be unique')
        return value
    
    def validate(self, attrs):
        """Validate variant data"""
        product = attrs.get('product')
        is_default = attrs.get('is_default', False)
        
        if is_default and product:
            # Check if there's already a default variant for this product
            existing_default = ProductVariant.objects.filter(
                product=product,
                is_default=True
            ).exclude(id=self.instance.id if self.instance else None)
            
            if existing_default.exists():
                raise serializers.ValidationError('Product already has a default variant')
        
        return attrs


class SupplierProductImageSerializer(serializers.ModelSerializer):
    """Serializer for product images in supplier context"""
    product_name = serializers.CharField(source='product.name', read_only=True)
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductImage
        fields = [
            'id', 'product', 'product_name', 'image', 'image_url',
            'alt_text', 'is_primary', 'display_order', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url
        return None


class SupplierProductImageCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating product images in supplier context"""
    
    class Meta:
        model = ProductImage
        fields = [
            'product', 'image', 'alt_text', 'is_primary', 'display_order'
        ]
    
    def validate(self, attrs):
        """Validate image data"""
        product = attrs.get('product')
        is_primary = attrs.get('is_primary', False)
        
        if is_primary and product:
            # Check if there's already a primary image for this product
            existing_primary = ProductImage.objects.filter(
                product=product,
                is_primary=True
            ).exclude(id=self.instance.id if self.instance else None)
            
            if existing_primary.exists():
                raise serializers.ValidationError('Product already has a primary image')
        
        return attrs


class SupplierProductStatsSerializer(serializers.Serializer):
    """Serializer for product statistics"""
    total_products = serializers.IntegerField()
    active_products = serializers.IntegerField()
    draft_products = serializers.IntegerField()
    low_stock_products = serializers.IntegerField()
    out_of_stock_products = serializers.IntegerField()
    total_variants = serializers.IntegerField()
    low_stock_variants = serializers.IntegerField()
    out_of_stock_variants = serializers.IntegerField()
    suppliers = serializers.ListField()


class SupplierCategorySerializer(serializers.ModelSerializer):
    """Serializer for categories in supplier context"""
    products_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'is_active', 'products_count']
    
    def get_products_count(self, obj):
        # Count products for the supplier's products only
        supplier = self.context.get('supplier')
        if supplier:
            return obj.products.filter(supplier=supplier).count()
        return obj.products.count()


class SupplierTagSerializer(serializers.ModelSerializer):
    """Serializer for tags in supplier context"""
    products_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Tag
        fields = ['id', 'name', 'description', 'is_active', 'products_count']
    
    def get_products_count(self, obj):
        # Count products for the supplier's products only
        supplier = self.context.get('supplier')
        if supplier:
            return obj.products.filter(supplier=supplier).count()
        return obj.products.count()
