"""
Optimal Scalable E-commerce Database Schema for Products with Multiple Attributes

This schema supports:
- Multiple attributes per product (size, color, RAM, storage, material, etc.)
- Reusable attribute values across products
- ProductVariants for each sellable combination (SKU)
- Stock and price at variant level
- Unlimited future growth and any product category
"""
from django.db import models
from django.core.exceptions import ValidationError


class Attribute(models.Model):
    """
    Global attributes that can be used across any product category.
    Examples: Color, Size, RAM, Storage, Material, Brand, etc.
    """
    name = models.CharField(max_length=100, unique=True, verbose_name='Attribute Name')
    slug = models.SlugField(max_length=100, unique=True, verbose_name='Attribute Slug')
    description = models.TextField(blank=True, verbose_name='Description')
    
    # Control how this attribute is displayed and used
    is_filterable = models.BooleanField(default=True, verbose_name='Can be used in filters')
    is_variant_defining = models.BooleanField(default=True, verbose_name='Defines product variants')
    display_order = models.PositiveIntegerField(default=0, verbose_name='Display Order')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['display_order', 'name']
        verbose_name = 'Attribute'
        verbose_name_plural = 'Attributes'
    
    def __str__(self):
        return self.name


class AttributeValue(models.Model):
    """
    Universal attribute values that can be reused across products.
    Examples: 
    - Color: Red, Blue, Green, Black, White
    - Size: XS, S, M, L, XL, XXL
    - RAM: 4GB, 8GB, 16GB, 32GB
    - Storage: 64GB, 128GB, 256GB, 512GB, 1TB
    """
    attribute = models.ForeignKey(
        Attribute, 
        on_delete=models.CASCADE, 
        related_name='values',
        verbose_name='Attribute'
    )
    value = models.CharField(max_length=100, verbose_name='Value')
    display_name = models.CharField(max_length=100, blank=True, verbose_name='Display Name')
    
    # Optional visual representation
    color_code = models.CharField(max_length=7, blank=True, null=True, verbose_name='Color Code (hex)')
    image = models.ImageField(upload_to='attribute_values/', blank=True, null=True, verbose_name='Image')
    
    # For ordering and organization
    display_order = models.PositiveIntegerField(default=0, verbose_name='Display Order')
    is_active = models.BooleanField(default=True, verbose_name='Is Active')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('attribute', 'value')
        ordering = ['display_order', 'value']
        verbose_name = 'Attribute Value'
        verbose_name_plural = 'Attribute Values'
    
    def __str__(self):
        return f"{self.attribute.name}: {self.value}"
    
    def get_display_name(self):
        return self.display_name if self.display_name else self.value


class Product(models.Model):
    """
    Base product model - represents the general product without specific variants.
    Examples: "iPhone 15", "Classic T-Shirt", "Running Shorts"
    """
    name = models.CharField(max_length=200, verbose_name='Product Name')
    slug = models.SlugField(max_length=200, unique=True, verbose_name='Product Slug')
    description = models.TextField(blank=True, verbose_name='Description')
    
    # Product organization
    category = models.ForeignKey('Category', on_delete=models.CASCADE, verbose_name='Category')
    brand = models.CharField(max_length=100, blank=True, verbose_name='Brand')
    
    # Product status
    is_active = models.BooleanField(default=True, verbose_name='Is Active')
    is_featured = models.BooleanField(default=False, verbose_name='Is Featured')
    
    # SEO and metadata
    meta_title = models.CharField(max_length=200, blank=True, verbose_name='Meta Title')
    meta_description = models.TextField(blank=True, verbose_name='Meta Description')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Product'
        verbose_name_plural = 'Products'
    
    def __str__(self):
        return self.name
    
    def get_available_attributes(self):
        """Get all attributes that have variants for this product"""
        return Attribute.objects.filter(
            values__variant_attributes__variant__product=self
        ).distinct()
    
    def get_variants_count(self):
        """Get total number of variants for this product"""
        return self.variants.filter(is_active=True).count()
    
    def get_price_range(self):
        """Get price range across all variants"""
        variants = self.variants.filter(is_active=True)
        if not variants:
            return None
        
        prices = variants.values_list('price', flat=True)
        min_price = min(prices)
        max_price = max(prices)
        
        if min_price == max_price:
            return min_price
        return (min_price, max_price)


class ProductVariant(models.Model):
    """
    Specific sellable combination of a product with unique attributes.
    Each variant represents a unique SKU that can be sold.
    Examples:
    - iPhone 15 - 128GB - Blue
    - Classic T-Shirt - Medium - Red
    - Running Shorts - Large - Black
    """
    product = models.ForeignKey(
        Product, 
        on_delete=models.CASCADE, 
        related_name='variants',
        verbose_name='Product'
    )
    
    # Unique identifier for this specific variant
    sku = models.CharField(max_length=100, unique=True, verbose_name='SKU')
    name = models.CharField(max_length=200, blank=True, verbose_name='Variant Name')
    
    # Pricing and inventory
    price = models.DecimalField(max_digits=12, decimal_places=2, verbose_name='Price')
    cost_price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, verbose_name='Cost Price')
    stock_quantity = models.PositiveIntegerField(default=0, verbose_name='Stock Quantity')
    
    # Variant-specific details
    weight = models.DecimalField(max_digits=10, decimal_places=3, null=True, blank=True, verbose_name='Weight (kg)')
    dimensions = models.CharField(max_length=100, blank=True, verbose_name='Dimensions')
    
    # Status
    is_active = models.BooleanField(default=True, verbose_name='Is Active')
    is_default = models.BooleanField(default=False, verbose_name='Is Default Variant')
    
    # Inventory management
    low_stock_threshold = models.PositiveIntegerField(default=5, verbose_name='Low Stock Alert Threshold')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['product', 'sku']
        verbose_name = 'Product Variant'
        verbose_name_plural = 'Product Variants'
    
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
    
    def is_in_stock(self):
        """Check if variant is in stock"""
        return self.stock_quantity > 0
    
    def is_low_stock(self):
        """Check if variant stock is below threshold"""
        return self.stock_quantity <= self.low_stock_threshold
    
    def save(self, *args, **kwargs):
        # Auto-generate name if not provided
        if not self.name:
            self.name = self.get_attribute_display()
        
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
    This is the key to making attributes universal and reusable.
    
    Why this model is essential:
    1. Allows multiple attributes per variant (color + size + RAM, etc.)
    2. Makes attribute values reusable across products ("Red" can be used for shirts, phones, etc.)
    3. Enables efficient filtering and searching
    4. Supports unlimited attribute combinations
    5. Maintains data integrity and consistency
    """
    variant = models.ForeignKey(
        ProductVariant, 
        on_delete=models.CASCADE, 
        related_name='variant_attributes',
        verbose_name='Product Variant'
    )
    attribute_value = models.ForeignKey(
        AttributeValue, 
        on_delete=models.CASCADE, 
        related_name='variant_attributes',
        verbose_name='Attribute Value'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('variant', 'attribute_value')
        verbose_name = 'Variant Attribute'
        verbose_name_plural = 'Variant Attributes'
    
    def __str__(self):
        return f"{self.variant.sku} - {self.attribute_value}"
    
    def clean(self):
        """Ensure no duplicate attributes for the same variant"""
        if VariantAttribute.objects.filter(
            variant=self.variant,
            attribute_value__attribute=self.attribute_value.attribute
        ).exclude(pk=self.pk).exists():
            raise ValidationError(
                f"Variant already has a value for attribute '{self.attribute_value.attribute.name}'"
            )


class Category(models.Model):
    """Product categories for organization"""
    name = models.CharField(max_length=100, unique=True, verbose_name='Category Name')
    slug = models.SlugField(max_length=100, unique=True, verbose_name='Category Slug')
    description = models.TextField(blank=True, verbose_name='Description')
    parent = models.ForeignKey(
        'self', 
        null=True, 
        blank=True, 
        on_delete=models.CASCADE, 
        related_name='subcategories',
        verbose_name='Parent Category'
    )
    
    is_active = models.BooleanField(default=True, verbose_name='Is Active')
    display_order = models.PositiveIntegerField(default=0, verbose_name='Display Order')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['display_order', 'name']
        verbose_name = 'Category'
        verbose_name_plural = 'Categories'
    
    def __str__(self):
        return self.name


# Example usage and data creation functions
def create_example_data():
    """
    Create example database entries demonstrating the schema:
    1. T-shirt with Color + Size attributes
    2. Shorts with Color + Size attributes  
    3. Phone with Color + RAM attributes
    """
    
    # Create Categories
    clothing_category = Category.objects.create(
        name="Clothing",
        slug="clothing"
    )
    
    electronics_category = Category.objects.create(
        name="Electronics", 
        slug="electronics"
    )
    
    # Create Attributes
    color_attr = Attribute.objects.create(
        name="Color",
        slug="color"
    )
    
    size_attr = Attribute.objects.create(
        name="Size", 
        slug="size"
    )
    
    ram_attr = Attribute.objects.create(
        name="RAM",
        slug="ram"
    )
    
    # Create Attribute Values
    # Colors (reusable across all products)
    red_color = AttributeValue.objects.create(
        attribute=color_attr,
        value="Red",
        color_code="#FF0000"
    )
    
    blue_color = AttributeValue.objects.create(
        attribute=color_attr,
        value="Blue", 
        color_code="#0000FF"
    )
    
    black_color = AttributeValue.objects.create(
        attribute=color_attr,
        value="Black",
        color_code="#000000"
    )
    
    # Sizes (reusable for clothing)
    size_m = AttributeValue.objects.create(
        attribute=size_attr,
        value="M"
    )
    
    size_l = AttributeValue.objects.create(
        attribute=size_attr,
        value="L"
    )
    
    # RAM options (for electronics)
    ram_8gb = AttributeValue.objects.create(
        attribute=ram_attr,
        value="8GB"
    )
    
    ram_16gb = AttributeValue.objects.create(
        attribute=ram_attr,
        value="16GB"
    )
    
    # Create Products
    tshirt_product = Product.objects.create(
        name="Classic T-Shirt",
        slug="classic-tshirt",
        description="Comfortable cotton t-shirt",
        category=clothing_category
    )
    
    shorts_product = Product.objects.create(
        name="Running Shorts",
        slug="running-shorts", 
        description="Athletic shorts for running",
        category=clothing_category
    )
    
    phone_product = Product.objects.create(
        name="Smartphone Pro",
        slug="smartphone-pro",
        description="Latest smartphone with advanced features",
        category=electronics_category
    )
    
    # Create Product Variants
    # T-Shirt variants: Red-M, Red-L, Blue-M, Blue-L
    tshirt_red_m = ProductVariant.objects.create(
        product=tshirt_product,
        sku="TSHIRT-RED-M",
        price=25.00,
        stock_quantity=50,
        is_default=True
    )
    
    tshirt_red_l = ProductVariant.objects.create(
        product=tshirt_product,
        sku="TSHIRT-RED-L", 
        price=25.00,
        stock_quantity=30
    )
    
    tshirt_blue_m = ProductVariant.objects.create(
        product=tshirt_product,
        sku="TSHIRT-BLUE-M",
        price=25.00,
        stock_quantity=40
    )
    
    tshirt_blue_l = ProductVariant.objects.create(
        product=tshirt_product,
        sku="TSHIRT-BLUE-L",
        price=25.00,
        stock_quantity=25
    )
    
    # Shorts variants: Black-M, Black-L  
    shorts_black_m = ProductVariant.objects.create(
        product=shorts_product,
        sku="SHORTS-BLACK-M",
        price=35.00,
        stock_quantity=20,
        is_default=True
    )
    
    shorts_black_l = ProductVariant.objects.create(
        product=shorts_product,
        sku="SHORTS-BLACK-L",
        price=35.00, 
        stock_quantity=15
    )
    
    # Phone variants: Blue-8GB, Blue-16GB, Black-8GB, Black-16GB
    phone_blue_8gb = ProductVariant.objects.create(
        product=phone_product,
        sku="PHONE-BLUE-8GB",
        price=699.00,
        stock_quantity=10,
        is_default=True
    )
    
    phone_blue_16gb = ProductVariant.objects.create(
        product=phone_product,
        sku="PHONE-BLUE-16GB", 
        price=799.00,
        stock_quantity=8
    )
    
    phone_black_8gb = ProductVariant.objects.create(
        product=phone_product,
        sku="PHONE-BLACK-8GB",
        price=699.00,
        stock_quantity=12
    )
    
    phone_black_16gb = ProductVariant.objects.create(
        product=phone_product,
        sku="PHONE-BLACK-16GB",
        price=799.00,
        stock_quantity=5
    )
    
    # Create VariantAttribute relationships
    # T-Shirt Red-M: Red color + M size
    VariantAttribute.objects.create(variant=tshirt_red_m, attribute_value=red_color)
    VariantAttribute.objects.create(variant=tshirt_red_m, attribute_value=size_m)
    
    # T-Shirt Red-L: Red color + L size  
    VariantAttribute.objects.create(variant=tshirt_red_l, attribute_value=red_color)
    VariantAttribute.objects.create(variant=tshirt_red_l, attribute_value=size_l)
    
    # T-Shirt Blue-M: Blue color + M size
    VariantAttribute.objects.create(variant=tshirt_blue_m, attribute_value=blue_color)
    VariantAttribute.objects.create(variant=tshirt_blue_m, attribute_value=size_m)
    
    # T-Shirt Blue-L: Blue color + L size
    VariantAttribute.objects.create(variant=tshirt_blue_l, attribute_value=blue_color)
    VariantAttribute.objects.create(variant=tshirt_blue_l, attribute_value=size_l)
    
    # Shorts Black-M: Black color + M size (reusing same color and size values!)
    VariantAttribute.objects.create(variant=shorts_black_m, attribute_value=black_color)
    VariantAttribute.objects.create(variant=shorts_black_m, attribute_value=size_m)
    
    # Shorts Black-L: Black color + L size
    VariantAttribute.objects.create(variant=shorts_black_l, attribute_value=black_color)
    VariantAttribute.objects.create(variant=shorts_black_l, attribute_value=size_l)
    
    # Phone Blue-8GB: Blue color + 8GB RAM (reusing blue color!)
    VariantAttribute.objects.create(variant=phone_blue_8gb, attribute_value=blue_color)
    VariantAttribute.objects.create(variant=phone_blue_8gb, attribute_value=ram_8gb)
    
    # Phone Blue-16GB: Blue color + 16GB RAM
    VariantAttribute.objects.create(variant=phone_blue_16gb, attribute_value=blue_color) 
    VariantAttribute.objects.create(variant=phone_blue_16gb, attribute_value=ram_16gb)
    
    # Phone Black-8GB: Black color + 8GB RAM (reusing black color!)
    VariantAttribute.objects.create(variant=phone_black_8gb, attribute_value=black_color)
    VariantAttribute.objects.create(variant=phone_black_8gb, attribute_value=ram_8gb)
    
    # Phone Black-16GB: Black color + 16GB RAM
    VariantAttribute.objects.create(variant=phone_black_16gb, attribute_value=black_color)
    VariantAttribute.objects.create(variant=phone_black_16gb, attribute_value=ram_16gb)
    
    print("Example data created successfully!")
    print("Notice how:")
    print("- 'Red', 'Blue', 'Black' colors are reused across T-shirts, Shorts, and Phones")
    print("- 'M' and 'L' sizes are reused between T-shirts and Shorts") 
    print("- Each variant has a unique SKU and can have different prices/stock")
    print("- The VariantAttribute table enables unlimited attribute combinations")
