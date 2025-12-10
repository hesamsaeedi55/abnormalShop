"""
🔥 DJANGO ADMIN SETUP for Product Variants

Update your shop/admin.py to handle product+variant creation easily
"""

from django.contrib import admin
from django.db import transaction
from django.forms import ModelForm, inlineformset_factory
from django.forms.models import BaseInlineFormSet
from shop.models import (
    Product, ProductVariant, VariantAttribute, 
    Attribute, NewAttributeValue
)


# ========================================
# INLINE ADMIN FOR VARIANTS
# ========================================

class VariantAttributeInline(admin.TabularInline):
    """Inline for adding attributes to variants"""
    model = VariantAttribute
    extra = 2
    autocomplete_fields = ['attribute_value']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'attribute_value__attribute'
        )


class ProductVariantInline(admin.TabularInline):
    """Inline for adding variants to products"""
    model = ProductVariant
    extra = 1
    
    fields = [
        'sku', 'variant_name', 'price_toman', 'price_usd', 
        'stock_quantity', 'is_active', 'is_default'
    ]
    
    readonly_fields = ['created_at', 'updated_at']


# ========================================
# ENHANCED PRODUCT ADMIN
# ========================================

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    """Enhanced Product admin with variant support"""
    
    list_display = [
        'name', 'category', 'brand', 'variants_count', 
        'total_stock', 'price_range', 'is_active'
    ]
    
    list_filter = ['category', 'brand', 'is_active', 'created_at']
    
    search_fields = ['name', 'description', 'variants__sku']
    
    prepopulated_fields = {'slug': ('name',)}
    
    inlines = [ProductVariantInline]
    
    fieldsets = (
        ('محصول', {
            'fields': ('name', 'slug', 'description', 'category', 'brand')
        }),
        ('وضعیت', {
            'fields': ('is_active', 'is_featured')
        }),
        ('SEO', {
            'fields': ('meta_title', 'meta_description'),
            'classes': ('collapse',)
        }),
    )
    
    def variants_count(self, obj):
        """Show number of variants"""
        return obj.variants.filter(is_active=True).count()
    variants_count.short_description = 'تعداد ترکیب‌ها'
    
    def total_stock(self, obj):
        """Show total stock across all variants"""
        return obj.get_total_stock()
    total_stock.short_description = 'کل موجودی'
    
    def price_range(self, obj):
        """Show price range"""
        return obj.get_price_range()
    price_range.short_description = 'محدوده قیمت'
    
    def get_queryset(self, request):
        return super().get_queryset(request).prefetch_related('variants')


# ========================================
# PRODUCT VARIANT ADMIN
# ========================================

@admin.register(ProductVariant)
class ProductVariantAdmin(admin.ModelAdmin):
    """Dedicated admin for managing variants"""
    
    list_display = [
        'sku', 'product', 'variant_name', 'formatted_price', 
        'stock_quantity', 'stock_status', 'is_default', 'is_active'
    ]
    
    list_filter = [
        'product__category', 'is_active', 'is_default', 
        'created_at', 'low_stock_threshold'
    ]
    
    search_fields = ['sku', 'product__name', 'variant_name']
    
    list_editable = ['price_toman', 'stock_quantity', 'is_active']
    
    inlines = [VariantAttributeInline]
    
    fieldsets = (
        ('اطلاعات اصلی', {
            'fields': ('product', 'sku', 'variant_name')
        }),
        ('قیمت‌گذاری', {
            'fields': ('price_toman', 'price_usd', 'cost_price')
        }),
        ('موجودی', {
            'fields': ('stock_quantity', 'low_stock_threshold')
        }),
        ('جزئیات', {
            'fields': ('weight', 'dimensions')
        }),
        ('وضعیت', {
            'fields': ('is_active', 'is_default')
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']
    
    def formatted_price(self, obj):
        """Show formatted price"""
        return obj.get_formatted_price()
    formatted_price.short_description = 'قیمت'
    
    def stock_status(self, obj):
        """Show stock status with colors"""
        if obj.stock_quantity == 0:
            return format_html('<span style="color: red;">ناموجود</span>')
        elif obj.is_low_stock():
            return format_html('<span style="color: orange;">کم‌موجود</span>')
        else:
            return format_html('<span style="color: green;">موجود</span>')
    stock_status.short_description = 'وضعیت موجودی'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('product')


# ========================================
# CUSTOM ADMIN ACTIONS
# ========================================

def create_variants_for_product(modeladmin, request, queryset):
    """Admin action to create variants for selected products"""
    
    for product in queryset:
        if product.variants.exists():
            continue  # Skip if already has variants
        
        # Create default variant
        ProductVariant.objects.create(
            product=product,
            sku=f"PROD-{product.id}",
            variant_name="پیش‌فرض",
            price_toman=getattr(product, 'price_toman', 0),
            stock_quantity=getattr(product, 'stock_quantity', 0),
            is_default=True,
            is_active=product.is_active
        )
    
    modeladmin.message_user(
        request, 
        f"ترکیب‌های پیش‌فرض برای {queryset.count()} محصول ایجاد شد."
    )

create_variants_for_product.short_description = "ایجاد ترکیب پیش‌فرض"


def duplicate_product_with_variants(modeladmin, request, queryset):
    """Admin action to duplicate products with all their variants"""
    
    for product in queryset:
        # Duplicate the product
        new_product = Product.objects.create(
            name=f"{product.name} (کپی)",
            slug=f"{product.slug}-copy",
            description=product.description,
            category=product.category,
            brand=product.brand,
            is_active=False  # Create as inactive
        )
        
        # Duplicate all variants
        for variant in product.variants.all():
            new_variant = ProductVariant.objects.create(
                product=new_product,
                sku=f"{variant.sku}-COPY",
                variant_name=variant.variant_name,
                price_toman=variant.price_toman,
                price_usd=variant.price_usd,
                stock_quantity=0,  # Reset stock
                is_active=variant.is_active,
                is_default=variant.is_default
            )
            
            # Copy attributes
            for variant_attr in variant.variant_attributes.all():
                VariantAttribute.objects.create(
                    variant=new_variant,
                    attribute_value=variant_attr.attribute_value
                )
    
    modeladmin.message_user(
        request,
        f"{queryset.count()} محصول با تمام ترکیب‌هایشان کپی شد."
    )

duplicate_product_with_variants.short_description = "کپی محصول با ترکیب‌ها"


# Add actions to ProductAdmin
ProductAdmin.actions = [
    create_variants_for_product, 
    duplicate_product_with_variants
]


# ========================================
# VARIANT ATTRIBUTE ADMIN
# ========================================

@admin.register(VariantAttribute)
class VariantAttributeAdmin(admin.ModelAdmin):
    """Admin for variant attributes"""
    
    list_display = [
        'variant', 'attribute_name', 'attribute_value', 'created_at'
    ]
    
    list_filter = [
        'attribute_value__attribute', 'variant__product__category'
    ]
    
    search_fields = [
        'variant__sku', 'variant__product__name', 
        'attribute_value__value'
    ]
    
    def attribute_name(self, obj):
        return obj.attribute_value.attribute.name
    attribute_name.short_description = 'ویژگی'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            'variant__product', 'attribute_value__attribute'
        )


# ========================================
# BULK VARIANT CREATION FORM
# ========================================

class BulkVariantCreationForm(ModelForm):
    """Custom form for creating multiple variants at once"""
    
    class Meta:
        model = Product
        fields = '__all__'
    
    def save(self, commit=True):
        product = super().save(commit)
        
        if commit:
            # Create variants based on form data
            # This would be customized based on your specific needs
            pass
        
        return product


# ========================================
# ADMIN CUSTOMIZATIONS
# ========================================

# Customize admin site header
admin.site.site_header = "مدیریت فروشگاه"
admin.site.site_title = "پنل مدیریت"
admin.site.index_title = "خوش آمدید به پنل مدیریت فروشگاه"


# ========================================
# USAGE INSTRUCTIONS
# ========================================

"""
🔥 SETUP INSTRUCTIONS:

1. Replace your current shop/admin.py with this code

2. Add these imports at the top:
   from django.utils.html import format_html

3. Register the new admin classes

4. Run the development server:
   python manage.py runserver

5. Go to admin panel:
   http://localhost:8000/admin/

6. Now you can:
   ✅ Create products with variants directly in admin
   ✅ Manage variant attributes inline
   ✅ See stock status with colors
   ✅ Use bulk actions to create variants
   ✅ Duplicate products with all variants

🔥 FEATURES:

✅ Product admin shows variant count and total stock
✅ Variant admin with inline attribute editing
✅ Stock status indicators (red/orange/green)
✅ Bulk actions for variant creation
✅ Search across products and variants
✅ Proper filtering and organization

🔥 WORKFLOW:

1. Create a product in admin
2. Add variants using the inline forms
3. Add attributes to each variant
4. Set prices and stock for each variant
5. Mark one variant as default
6. Activate the product

That's it! Your admin now fully supports the variant system.
"""
