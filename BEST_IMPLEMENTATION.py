"""
🔥 BEST IMPLEMENTATION: Product Variant System for Your Django Project

This is the optimal combination of all the solutions I created.
Copy these models into your shop/models.py
"""

from django.db import models, transaction
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal


# ========================================
# CORE VARIANT MODELS
# ========================================

class ProductVariant(models.Model):
    """
    🔥 CRITICAL: Individual SKU for each product combination
    
    Solves:
    - Unique SKUs per combination (IPHONE-RED-128GB)
    - Individual pricing per variant
    - Individual stock tracking
    - Unlimited attribute combinations
    """
    
    product = models.ForeignKey(
        'Product',
        on_delete=models.CASCADE, 
        related_name='variants',
        verbose_name='محصول'
    )
    
    # 🔥 CRITICAL: Unique SKU for each combination
    sku = models.CharField(
        max_length=100, 
        unique=True, 
        verbose_name='کد محصول (SKU)',
        help_text='کد یکتا: IPHONE-RED-128GB, TSHIRT-BLUE-M'
    )
    
    variant_name = models.CharField(
        max_length=200, 
        blank=True, 
        verbose_name='نام ترکیب',
        help_text='مثل: قرمز - ۱۲۸ گیگ'
    )
    
    # 🔥 CRITICAL: Individual pricing per variant
    price_toman = models.DecimalField(
        max_digits=12, 
        decimal_places=0, 
        verbose_name='قیمت (تومان)',
        help_text='قیمت این ترکیب خاص'
    )
    
    price_usd = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        null=True, 
        blank=True, 
        verbose_name='قیمت (دلار)'
    )
    
    # 🔥 CRITICAL: Individual stock per variant
    stock_quantity = models.PositiveIntegerField(
        default=0, 
        verbose_name='موجودی',
        help_text='موجودی این ترکیب خاص'
    )
    
    # Status and management
    is_active = models.BooleanField(default=True, verbose_name='فعال')
    is_default = models.BooleanField(default=False, verbose_name='ترکیب پیش‌فرض')
    low_stock_threshold = models.PositiveIntegerField(default=5, verbose_name='آستانه کمبود موجودی')
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['product', 'sku']
        verbose_name = 'ترکیب محصول'
        verbose_name_plural = 'ترکیب‌های محصول'
    
    def __str__(self):
        if self.variant_name:
            return f"{self.product.name} - {self.variant_name}"
        return f"{self.product.name} - {self.sku}"
    
    def get_formatted_price(self):
        return f"{self.price_toman:,.0f} تومان"
    
    def is_in_stock(self):
        return self.stock_quantity > 0
    
    def is_low_stock(self):
        return self.stock_quantity <= self.low_stock_threshold
    
    def get_attribute_display(self):
        """Get formatted string of all attributes"""
        attributes = []
        for variant_attr in self.variant_attributes.select_related('attribute_value__attribute'):
            attr_value = variant_attr.attribute_value
            attributes.append(f"{attr_value.attribute.name}: {attr_value.value}")
        return " | ".join(attributes)
    
    def save(self, *args, **kwargs):
        # Auto-generate variant name if not provided
        if not self.variant_name:
            self.variant_name = self.get_attribute_display()
        
        # Ensure only one default variant per product
        if self.is_default:
            ProductVariant.objects.filter(
                product=self.product, 
                is_default=True
            ).exclude(pk=self.pk).update(is_default=False)
        
        super().save(*args, **kwargs)


class VariantAttribute(models.Model):
    """
    🔥 CRITICAL: Junction table for universal attributes
    
    Enables:
    - Multiple attributes per variant
    - Reusable attribute values across products
    - Unlimited combinations
    - Efficient filtering
    """
    
    variant = models.ForeignKey(
        ProductVariant, 
        on_delete=models.CASCADE, 
        related_name='variant_attributes',
        verbose_name='ترکیب محصول'
    )
    
    attribute_value = models.ForeignKey(
        'NewAttributeValue',
        on_delete=models.CASCADE, 
        related_name='variant_attributes',
        verbose_name='مقدار ویژگی'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('variant', 'attribute_value')
        verbose_name = 'ویژگی ترکیب'
        verbose_name_plural = 'ویژگی‌های ترکیب'
    
    def __str__(self):
        return f"{self.variant.sku} - {self.attribute_value}"
    
    def clean(self):
        """Ensure no duplicate attributes for the same variant"""
        if VariantAttribute.objects.filter(
            variant=self.variant,
            attribute_value__attribute=self.attribute_value.attribute
        ).exclude(pk=self.pk).exists():
            raise ValidationError(
                f"این ترکیب قبلاً مقداری برای ویژگی '{self.attribute_value.attribute.name}' دارد"
            )


# ========================================
# PRODUCT MODEL EXTENSIONS
# ========================================

"""
🔥 ADD THESE METHODS TO YOUR EXISTING PRODUCT MODEL:

class Product(models.Model):
    # ... your existing fields ...
    
    def get_variants(self):
        '''Get all active variants for this product'''
        return self.variants.filter(is_active=True)
    
    def get_default_variant(self):
        '''Get the default variant for display'''
        return self.variants.filter(is_default=True, is_active=True).first()
    
    def get_price_range(self):
        '''Get price range across all variants'''
        variants = self.get_variants()
        if not variants.exists():
            return self.price_toman if hasattr(self, 'price_toman') else "قیمت تعیین نشده"
        
        prices = list(variants.values_list('price_toman', flat=True))
        min_price = min(prices)
        max_price = max(prices)
        
        if min_price == max_price:
            return f"{min_price:,.0f} تومان"
        return f"{min_price:,.0f} - {max_price:,.0f} تومان"
    
    def get_total_stock(self):
        '''Get total stock across all variants'''
        total = self.variants.filter(is_active=True).aggregate(
            total=models.Sum('stock_quantity')
        )['total']
        return total or 0
    
    def is_in_stock(self):
        '''Check if any variant is in stock'''
        return self.get_total_stock() > 0
    
    def has_variants(self):
        '''Check if product has any variants'''
        return self.variants.filter(is_active=True).exists()
"""


# ========================================
# EASY CREATION HELPER CLASS
# ========================================

class ProductVariantCreator:
    """
    🔥 BEST WAY to create products with variants
    """
    
    def __init__(self, product_data):
        self.product_data = product_data
        self.variants_data = []
    
    def add_variant(self, attributes_dict, price_toman, stock_quantity, **kwargs):
        """Add a variant with specific attributes"""
        variant_data = {
            'attributes': attributes_dict,
            'price_toman': price_toman,
            'stock_quantity': stock_quantity,
            **kwargs
        }
        self.variants_data.append(variant_data)
        return self
    
    def create(self):
        """Create the product with all its variants"""
        with transaction.atomic():
            # Import here to avoid circular imports
            from shop.models import Product, Attribute, NewAttributeValue
            
            # Create base product
            product = Product.objects.create(**self.product_data)
            
            created_variants = []
            
            for i, variant_data in enumerate(self.variants_data):
                # Generate SKU from attributes
                sku_parts = [self.product_data['name'].upper().replace(' ', '')[:8]]
                for attr_key, attr_value in variant_data['attributes'].items():
                    sku_parts.append(str(attr_value).upper())
                sku = '-'.join(sku_parts)
                
                # Create variant
                variant = ProductVariant.objects.create(
                    product=product,
                    sku=sku,
                    variant_name=' - '.join(variant_data['attributes'].values()),
                    price_toman=variant_data['price_toman'],
                    stock_quantity=variant_data['stock_quantity'],
                    is_active=True,
                    is_default=(i == 0)
                )
                
                # Link attributes
                for attr_key, attr_value in variant_data['attributes'].items():
                    try:
                        attribute = Attribute.objects.get(key=attr_key)
                        attr_value_obj = NewAttributeValue.objects.get(
                            attribute=attribute, 
                            value=attr_value
                        )
                        VariantAttribute.objects.create(
                            variant=variant, 
                            attribute_value=attr_value_obj
                        )
                    except (Attribute.DoesNotExist, NewAttributeValue.DoesNotExist):
                        print(f"⚠️ Attribute {attr_key}={attr_value} not found")
                
                created_variants.append(variant)
            
            return product, created_variants


# ========================================
# MIGRATION FUNCTION
# ========================================

def migrate_existing_products_to_variants():
    """
    🚨 CRITICAL: Run this ONCE after adding the models
    """
    from shop.models import Product
    
    print("🚨 MIGRATING EXISTING PRODUCTS TO VARIANTS...")
    
    migrated_count = 0
    
    for product in Product.objects.filter(is_active=True):
        # Skip if already has variants
        if hasattr(product, 'variants') and product.variants.exists():
            continue
        
        # Create default variant with current product data
        variant = ProductVariant.objects.create(
            product=product,
            sku=product.sku or f"PROD-{product.id}",
            variant_name="پیش‌فرض",
            price_toman=getattr(product, 'price_toman', 0),
            stock_quantity=getattr(product, 'stock_quantity', 0),
            is_active=product.is_active,
            is_default=True
        )
        
        # Migrate existing attributes
        if hasattr(product, 'attribute_values'):
            for attr_value in product.attribute_values.filter(attribute_value__isnull=False):
                VariantAttribute.objects.create(
                    variant=variant,
                    attribute_value=attr_value.attribute_value
                )
        
        migrated_count += 1
        print(f"✅ Migrated: {product.name} → {variant.sku}")
    
    print(f"🎉 MIGRATION COMPLETE! {migrated_count} products migrated")


# ========================================
# USAGE EXAMPLES
# ========================================

def create_sample_products():
    """Create sample products to test the system"""
    
    print("🔥 CREATING SAMPLE PRODUCTS...")
    
    # Example 1: T-Shirt with colors and sizes
    tshirt_creator = ProductVariantCreator({
        'name': 'Classic T-Shirt',
        'slug': 'classic-tshirt',
        'description': 'Comfortable cotton t-shirt',
        'category_id': 1,  # Your clothing category
        'brand': 'Fashion Brand',
        'is_active': True
    })
    
    colors = ['Red', 'Blue', 'Black']
    sizes = ['S', 'M', 'L']
    
    for color in colors:
        for size in sizes:
            price = 280000 if color == 'Black' else 250000  # Black premium
            tshirt_creator.add_variant(
                {"color": color, "size": size}, 
                price, 
                30
            )
    
    tshirt_product, tshirt_variants = tshirt_creator.create()
    print(f"✅ Created {tshirt_product.name} with {len(tshirt_variants)} variants")
    
    # Example 2: Phone with storage options
    phone_creator = ProductVariantCreator({
        'name': 'iPhone 15 Pro',
        'slug': 'iphone-15-pro',
        'description': 'Latest iPhone with Pro features',
        'category_id': 2,  # Your electronics category
        'brand': 'Apple',
        'is_active': True
    })
    
    combinations = [
        {"color": "Blue", "storage": "128GB", "price": 35000000, "stock": 15},
        {"color": "Blue", "storage": "256GB", "price": 38000000, "stock": 12},
        {"color": "Black", "storage": "128GB", "price": 35500000, "stock": 10},
        {"color": "Black", "storage": "256GB", "price": 38500000, "stock": 8},
    ]
    
    for combo in combinations:
        phone_creator.add_variant(
            {"color": combo["color"], "storage": combo["storage"]},
            combo["price"],
            combo["stock"]
        )
    
    phone_product, phone_variants = phone_creator.create()
    print(f"✅ Created {phone_product.name} with {len(phone_variants)} variants")
    
    return [tshirt_product, phone_product]


# ========================================
# QUICK TEST FUNCTIONS
# ========================================

def test_variant_system():
    """Test the variant system functionality"""
    
    print("🔥 TESTING VARIANT SYSTEM...")
    
    # Test 1: Get all products with variants
    from shop.models import Product
    
    for product in Product.objects.all()[:5]:
        print(f"\n📱 {product.name}:")
        print(f"  Variants: {product.get_variants().count()}")
        print(f"  Total Stock: {product.get_total_stock()}")
        print(f"  Price Range: {product.get_price_range()}")
        
        for variant in product.get_variants()[:3]:
            print(f"    • {variant.sku}: {variant.get_formatted_price()} ({variant.stock_quantity} units)")
    
    # Test 2: Find variants by attributes
    print(f"\n🔍 FINDING VARIANTS BY ATTRIBUTES:")
    
    red_variants = ProductVariant.objects.filter(
        variant_attributes__attribute_value__value="Red"
    ).distinct()
    
    print(f"Red variants found: {red_variants.count()}")
    for variant in red_variants[:3]:
        print(f"  • {variant.sku}: {variant.get_attribute_display()}")


if __name__ == "__main__":
    # Run these functions after setting up the models
    print("🔥 PRODUCT VARIANT SYSTEM READY!")
    print("Run these functions to test:")
    print("1. migrate_existing_products_to_variants()")
    print("2. create_sample_products()")
    print("3. test_variant_system()")
