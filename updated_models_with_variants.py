"""
Updated Django Models - Adding ProductVariant System to Current Implementation

This file shows how to add the new ProductVariant and VariantAttribute models
to your existing shop/models.py while maintaining backward compatibility.

INSTRUCTIONS:
1. Add these models to your existing shop/models.py
2. Run: python manage.py makemigrations shop
3. Run: python manage.py migrate
4. Run the migration script to convert existing data
"""

from django.db import models
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal


class ProductVariant(models.Model):
    """
    Specific sellable combination of a product with unique attributes.
    Each variant represents a unique SKU that can be sold.
    
    This enables:
    - Individual pricing per combination (Red iPhone vs Blue iPhone)
    - Individual stock tracking per combination
    - Unique SKUs for each sellable variant
    """
    product = models.ForeignKey(
        'Product',  # Reference to existing Product model
        on_delete=models.CASCADE, 
        related_name='variants',
        verbose_name='محصول'
    )
    
    # Unique identifier for this specific variant
    sku = models.CharField(
        max_length=100, 
        unique=True, 
        verbose_name='کد محصول (SKU)',
        help_text='کد یکتا برای این ترکیب خاص از محصول'
    )
    
    name = models.CharField(
        max_length=200, 
        blank=True, 
        verbose_name='نام ترکیب',
        help_text='نام نمایشی برای این ترکیب (مثل: قرمز - متوسط)'
    )
    
    # Pricing and inventory at variant level
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
    
    cost_price = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        null=True, 
        blank=True, 
        verbose_name='قیمت تمام‌شده'
    )
    
    stock_quantity = models.PositiveIntegerField(
        default=0, 
        verbose_name='تعداد موجودی',
        help_text='موجودی این ترکیب خاص'
    )
    
    # Variant-specific details
    weight = models.DecimalField(
        max_digits=10, 
        decimal_places=3, 
        null=True, 
        blank=True, 
        verbose_name='وزن (کیلوگرم)'
    )
    
    dimensions = models.CharField(
        max_length=100, 
        blank=True, 
        verbose_name='ابعاد'
    )
    
    # Status fields
    is_active = models.BooleanField(
        default=True, 
        verbose_name='فعال'
    )
    
    is_default = models.BooleanField(
        default=False, 
        verbose_name='ترکیب پیش‌فرض',
        help_text='آیا این ترکیب پیش‌فرض محصول است؟'
    )
    
    # Inventory management
    low_stock_threshold = models.PositiveIntegerField(
        default=5, 
        verbose_name='آستانه کمبود موجودی'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='تاریخ ایجاد')
    updated_at = models.DateTimeField(auto_now=True, verbose_name='تاریخ بروزرسانی')
    
    class Meta:
        ordering = ['product', 'sku']
        verbose_name = 'ترکیب محصول'
        verbose_name_plural = 'ترکیب‌های محصول'
    
    def __str__(self):
        if self.name:
            return f"{self.product.name} - {self.name}"
        return f"{self.product.name} - {self.sku}"
    
    def get_attribute_display(self):
        """Get formatted string of all attributes for this variant"""
        attributes = []
        for variant_attr in self.variant_attributes.select_related('attribute_value__attribute'):
            attr_value = variant_attr.attribute_value
            attributes.append(f"{attr_value.attribute.name}: {attr_value.value}")
        return " | ".join(attributes)
    
    def get_formatted_price(self):
        """Returns the formatted price with currency symbol"""
        if self.price_toman:
            return f"{self.price_toman:,.0f} تومان"
        elif self.price_usd:
            return f"${self.price_usd:,.2f}"
        return "قیمت تعیین نشده"
    
    def is_in_stock(self):
        """Check if variant is in stock"""
        return self.stock_quantity > 0
    
    def is_low_stock(self):
        """Check if variant stock is below threshold"""
        return self.stock_quantity <= self.low_stock_threshold
    
    def get_attributes_dict(self):
        """Get all attribute values as a dictionary"""
        attributes = {}
        for variant_attr in self.variant_attributes.select_related('attribute_value__attribute'):
            attr_value = variant_attr.attribute_value
            attributes[attr_value.attribute.key] = attr_value.value
        return attributes
    
    def save(self, *args, **kwargs):
        # Auto-generate name if not provided
        if not self.name:
            attr_display = self.get_attribute_display()
            if attr_display:
                self.name = attr_display
        
        # Ensure only one default variant per product
        if self.is_default:
            ProductVariant.objects.filter(
                product=self.product, 
                is_default=True
            ).exclude(pk=self.pk).update(is_default=False)
        
        super().save(*args, **kwargs)


class VariantAttribute(models.Model):
    """
    Junction table linking ProductVariants to AttributeValues.
    
    This is the KEY to making attributes universal and reusable:
    - Allows multiple attributes per variant (color + size + RAM, etc.)
    - Makes attribute values reusable across products
    - Enables unlimited attribute combinations
    - Supports efficient filtering and searching
    """
    variant = models.ForeignKey(
        ProductVariant, 
        on_delete=models.CASCADE, 
        related_name='variant_attributes',
        verbose_name='ترکیب محصول'
    )
    
    attribute_value = models.ForeignKey(
        'NewAttributeValue',  # Reference to existing NewAttributeValue model
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
                f"این ترکیب قبلاً مقداری برای ویژگی '{self.attribute_value.attribute.name}' دارد"
            )


# Extensions to existing Product model (add these methods)
class ProductExtensions:
    """
    Add these methods to your existing Product model
    """
    
    def get_variants(self):
        """Get all active variants for this product"""
        return self.variants.filter(is_active=True)
    
    def get_default_variant(self):
        """Get the default variant for this product"""
        return self.variants.filter(is_default=True, is_active=True).first()
    
    def get_price_range(self):
        """Get price range across all variants"""
        variants = self.get_variants()
        if not variants:
            return self.price_toman  # Fallback to product-level price
        
        prices = variants.values_list('price_toman', flat=True)
        min_price = min(prices)
        max_price = max(prices)
        
        if min_price == max_price:
            return min_price
        return (min_price, max_price)
    
    def get_total_stock(self):
        """Get total stock across all variants"""
        return self.variants.filter(is_active=True).aggregate(
            total=models.Sum('stock_quantity')
        )['total'] or 0
    
    def has_variants(self):
        """Check if product has any variants"""
        return self.variants.filter(is_active=True).exists()
    
    def get_available_attributes(self):
        """Get all attributes that have variants for this product"""
        from shop.models import Attribute  # Adjust import as needed
        return Attribute.objects.filter(
            values__variant_attributes__variant__product=self,
            values__variant_attributes__variant__is_active=True
        ).distinct()


# Helper functions for working with variants

def get_variant_by_attributes(product, attributes_dict):
    """
    Find a variant by its attribute combination
    
    Example:
    variant = get_variant_by_attributes(
        product=tshirt,
        attributes_dict={'color': 'Red', 'size': 'M'}
    )
    """
    variants = product.variants.filter(is_active=True)
    
    for variant in variants:
        variant_attrs = variant.get_attributes_dict()
        if all(variant_attrs.get(key) == value for key, value in attributes_dict.items()):
            return variant
    
    return None


def get_products_by_attribute(attribute_key, attribute_value):
    """
    Get all products that have a specific attribute value
    
    Example:
    red_products = get_products_by_attribute('color', 'Red')
    """
    from shop.models import Product  # Adjust import as needed
    
    return Product.objects.filter(
        variants__variant_attributes__attribute_value__attribute__key=attribute_key,
        variants__variant_attributes__attribute_value__value=attribute_value,
        variants__is_active=True
    ).distinct()


def get_attribute_values_for_products(products, attribute_key):
    """
    Get all available values for a specific attribute across multiple products
    
    Example:
    available_colors = get_attribute_values_for_products(
        products=clothing_products,
        attribute_key='color'
    )
    """
    from shop.models import NewAttributeValue  # Adjust import as needed
    
    return NewAttributeValue.objects.filter(
        attribute__key=attribute_key,
        variant_attributes__variant__product__in=products,
        variant_attributes__variant__is_active=True
    ).distinct().order_by('display_order', 'value')


# Migration utilities

def create_default_variants_for_existing_products():
    """
    Utility function to create default variants for existing products
    that don't have any variants yet.
    """
    from shop.models import Product  # Adjust import as needed
    
    products_without_variants = Product.objects.filter(
        variants__isnull=True
    )
    
    created_count = 0
    
    for product in products_without_variants:
        variant = ProductVariant.objects.create(
            product=product,
            sku=product.sku or f"PROD-{product.id}",
            name="پیش‌فرض",
            price_toman=product.price_toman or 0,
            price_usd=product.price_usd,
            stock_quantity=product.stock_quantity,
            weight=product.weight,
            dimensions=product.dimensions,
            is_active=product.is_active,
            is_default=True
        )
        
        # Migrate existing attributes
        for attr_value in product.attribute_values.filter(attribute_value__isnull=False):
            VariantAttribute.objects.create(
                variant=variant,
                attribute_value=attr_value.attribute_value
            )
        
        created_count += 1
    
    print(f"Created {created_count} default variants")


"""
INTEGRATION STEPS:

1. Add ProductVariant and VariantAttribute models to your shop/models.py

2. Add the extension methods to your existing Product model:
   
   class Product(models.Model):
       # ... existing fields ...
       
       def get_variants(self):
           return self.variants.filter(is_active=True)
       
       def get_default_variant(self):
           return self.variants.filter(is_default=True, is_active=True).first()
       
       # ... other extension methods ...

3. Run migrations:
   python manage.py makemigrations shop
   python manage.py migrate

4. Run the data migration script:
   python manage.py migrate_to_variants --dry-run  # Test first
   python manage.py migrate_to_variants           # Actual migration

5. Update your views and templates to work with variants:
   
   # In views.py
   def product_detail(request, product_slug):
       product = get_object_or_404(Product, slug=product_slug)
       variants = product.get_variants()
       default_variant = product.get_default_variant()
       
       context = {
           'product': product,
           'variants': variants,
           'default_variant': default_variant,
           'price_range': product.get_price_range(),
       }
       return render(request, 'product_detail.html', context)

6. Update templates to show variant information:
   
   {% for variant in variants %}
       <div class="variant">
           <strong>{{ variant.name }}</strong>
           <span class="price">{{ variant.get_formatted_price }}</span>
           <span class="stock">{{ variant.stock_quantity }} عدد</span>
           {% if variant.is_low_stock %}
               <span class="warning">موجودی کم!</span>
           {% endif %}
       </div>
   {% endfor %}

BENEFITS AFTER IMPLEMENTATION:
✅ Individual SKUs for each product combination
✅ Variant-specific pricing and inventory
✅ Unlimited scalability for new attributes
✅ Efficient filtering and search
✅ Backward compatibility maintained
✅ Future-proof architecture
"""
