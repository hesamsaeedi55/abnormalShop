"""
EMERGENCY VARIANT SYSTEM - Add to your shop/models.py IMMEDIATELY

This solves ALL 4 critical problems:
1. ✅ ProductVariant concept
2. ✅ Variant-level pricing/stock  
3. ✅ Unique SKUs per combination
4. ✅ Individual inventory tracking

Copy these models into your existing shop/models.py file.
"""

from django.db import models
from django.core.exceptions import ValidationError


class ProductVariant(models.Model):
    """
    🚨 CRITICAL: This model solves the variant problem
    
    Each variant = One sellable combination with unique:
    - SKU (IPHONE-RED-128GB)
    - Price (Red iPhone costs more than Blue)
    - Stock (15 Red vs 8 Blue iPhones)
    """
    
    # Link to your existing Product model
    product = models.ForeignKey(
        'Product',  # Your existing Product model
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
    
    # Display name for this specific combination
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
        help_text='قیمت این ترکیب خاص - می‌تواند از سایرین متفاوت باشد'
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
        help_text='موجودی این ترکیب خاص - جداگانه از سایرین'
    )
    
    # Variant status
    is_active = models.BooleanField(default=True, verbose_name='فعال')
    is_default = models.BooleanField(
        default=False, 
        verbose_name='ترکیب پیش‌فرض',
        help_text='ترکیبی که به صورت پیش‌فرض نمایش داده می‌شود'
    )
    
    # Additional variant details
    weight = models.DecimalField(
        max_digits=10, 
        decimal_places=3, 
        null=True, 
        blank=True, 
        verbose_name='وزن (کیلوگرم)'
    )
    
    # Inventory management
    low_stock_threshold = models.PositiveIntegerField(
        default=5, 
        verbose_name='آستانه کمبود موجودی'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='تاریخ ایجاد')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='آخرین بروزرسانی')
    
    class Meta:
        ordering = ['product', 'sku']
        verbose_name = 'ترکیب محصول'
        verbose_name_plural = 'ترکیب‌های محصول'
        
        # Ensure only one default variant per product
        constraints = [
            models.UniqueConstraint(
                fields=['product'],
                condition=models.Q(is_default=True),
                name='one_default_variant_per_product'
            )
        ]
    
    def __str__(self):
        if self.variant_name:
            return f"{self.product.name} - {self.variant_name}"
        return f"{self.product.name} - {self.sku}"
    
    def get_formatted_price(self):
        """Get formatted price string"""
        return f"{self.price_toman:,.0f} تومان"
    
    def is_in_stock(self):
        """Check if this specific variant is in stock"""
        return self.stock_quantity > 0
    
    def is_low_stock(self):
        """Check if this specific variant is low on stock"""
        return self.stock_quantity <= self.low_stock_threshold
    
    def get_attribute_display(self):
        """Get display string of all attributes for this variant"""
        attributes = []
        for variant_attr in self.variant_attributes.select_related(
            'attribute_value__attribute'
        ):
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
    🚨 CRITICAL: This model links variants to specific attribute combinations
    
    This enables:
    - Multiple attributes per variant (Color + Size + Storage)
    - Reusable attribute values across products
    - Efficient filtering and searching
    """
    
    variant = models.ForeignKey(
        ProductVariant, 
        on_delete=models.CASCADE, 
        related_name='variant_attributes',
        verbose_name='ترکیب محصول'
    )
    
    # Link to your existing NewAttributeValue model
    attribute_value = models.ForeignKey(
        'NewAttributeValue',  # Your existing model
        on_delete=models.CASCADE, 
        related_name='variant_attributes',
        verbose_name='مقدار ویژگی'
    )
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='تاریخ ایجاد')
    
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
                f"این ترکیب قبلاً مقداری برای ویژگی "
                f"'{self.attribute_value.attribute.name}' دارد"
            )


# 🔥 CRITICAL: Add these methods to your existing Product model
"""
Add these methods to your existing Product model in shop/models.py:

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
            return self.price_toman  # Fallback to product price
        
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
    
    def get_available_attributes(self):
        '''Get all attributes that have variants for this product'''
        from shop.models import Attribute
        return Attribute.objects.filter(
            values__variant_attributes__variant__product=self,
            values__variant_attributes__variant__is_active=True
        ).distinct()
"""


# 🚨 EMERGENCY FUNCTIONS - Use these immediately after adding models

def create_emergency_variants():
    """
    🚨 EMERGENCY: Create variants for existing products
    Run this IMMEDIATELY after adding the models
    """
    from shop.models import Product
    
    print("🚨 CREATING EMERGENCY VARIANTS...")
    
    created_count = 0
    
    for product in Product.objects.filter(is_active=True):
        # Skip if product already has variants
        if hasattr(product, 'variants') and product.variants.exists():
            continue
        
        # Generate SKU
        sku = product.sku if product.sku else f"PROD-{product.id}"
        
        # Create default variant
        variant = ProductVariant.objects.create(
            product=product,
            sku=sku,
            variant_name="پیش‌فرض",
            price_toman=product.price_toman or 0,
            price_usd=product.price_usd,
            stock_quantity=product.stock_quantity,
            is_active=product.is_active,
            is_default=True
        )
        
        # Migrate existing attributes to variant
        for attr_value in product.attribute_values.filter(attribute_value__isnull=False):
            VariantAttribute.objects.create(
                variant=variant,
                attribute_value=attr_value.attribute_value
            )
        
        created_count += 1
        print(f"✅ Created variant for: {product.name} (SKU: {sku})")
    
    print(f"🎉 EMERGENCY COMPLETE! Created {created_count} variants")


def create_specific_variants_example():
    """
    🔥 EXAMPLE: How to create specific variants for a product
    """
    from shop.models import Product, Attribute, NewAttributeValue
    
    # Example: Create iPhone variants
    iphone = Product.objects.get(name__icontains="iPhone")
    
    # Get color and storage attributes
    color_attr = Attribute.objects.get(key="color")
    storage_attr = Attribute.objects.get(key="storage")
    
    # Get attribute values
    red = NewAttributeValue.objects.get(attribute=color_attr, value="Red")
    blue = NewAttributeValue.objects.get(attribute=color_attr, value="Blue")
    gb_128 = NewAttributeValue.objects.get(attribute=storage_attr, value="128GB")
    gb_256 = NewAttributeValue.objects.get(attribute=storage_attr, value="256GB")
    
    # Create specific variants
    variants_data = [
        {"sku": "IPHONE-RED-128GB", "color": red, "storage": gb_128, "price": 14500000, "stock": 15},
        {"sku": "IPHONE-RED-256GB", "color": red, "storage": gb_256, "price": 16000000, "stock": 8},
        {"sku": "IPHONE-BLUE-128GB", "color": blue, "storage": gb_128, "price": 14500000, "stock": 12},
        {"sku": "IPHONE-BLUE-256GB", "color": blue, "storage": gb_256, "price": 16000000, "stock": 5},
    ]
    
    for data in variants_data:
        variant = ProductVariant.objects.create(
            product=iphone,
            sku=data["sku"],
            price_toman=data["price"],
            stock_quantity=data["stock"],
            is_active=True
        )
        
        # Add attributes
        VariantAttribute.objects.create(variant=variant, attribute_value=data["color"])
        VariantAttribute.objects.create(variant=variant, attribute_value=data["storage"])
        
        print(f"✅ Created: {data['sku']} - {data['price']:,} تومان - {data['stock']} units")


def get_variant_by_attributes(product, attributes_dict):
    """
    🔥 CRITICAL: Find specific variant by attributes
    
    Example:
    variant = get_variant_by_attributes(
        product=iphone,
        attributes_dict={"color": "Red", "storage": "128GB"}
    )
    """
    variants = product.variants.filter(is_active=True)
    
    for variant in variants:
        variant_attrs = {}
        for va in variant.variant_attributes.select_related('attribute_value__attribute'):
            variant_attrs[va.attribute_value.attribute.key] = va.attribute_value.value
        
        # Check if all requested attributes match
        if all(variant_attrs.get(key) == value for key, value in attributes_dict.items()):
            return variant
    
    return None


# 🚨 USAGE EXAMPLES

"""
# 1. CREATE VARIANTS FOR EXISTING PRODUCTS
create_emergency_variants()

# 2. GET VARIANTS FOR A PRODUCT
product = Product.objects.get(id=1)
variants = product.get_variants()
for variant in variants:
    print(f"{variant.sku}: {variant.get_formatted_price()} - {variant.stock_quantity} units")

# 3. FIND SPECIFIC VARIANT
red_medium_tshirt = get_variant_by_attributes(
    product=tshirt,
    attributes_dict={"color": "Red", "size": "M"}
)

# 4. CHECK STOCK FOR SPECIFIC COMBINATION
if red_medium_tshirt and red_medium_tshirt.is_in_stock():
    print("Red Medium T-shirt is available!")
else:
    print("Red Medium T-shirt is out of stock!")

# 5. UPDATE STOCK FOR SPECIFIC VARIANT
red_medium_tshirt.stock_quantity -= 1  # Sold one
red_medium_tshirt.save()
"""
