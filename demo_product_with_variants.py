#!/usr/bin/env python3
"""
Demo script to create a product with variants
Run this to demonstrate the variant system functionality
"""

import os
import sys
import django

# Setup Django environment
sys.path.append('/Users/hesamoddinsaeedi/Desktop/best/backup copy 53/myshop2')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from shop.models import Product, ProductVariant, Category
from suppliers.models import Supplier

def create_demo_product_with_variants():
    """Create a demo product (iPhone) with multiple variants"""
    
    print("🚀 Creating demo product with variants...")
    
    # Get or create a category
    try:
        category = Category.objects.get(pk=1045)  # Using the category from your URL
        print(f"✅ Using existing category: {category.name}")
    except Category.DoesNotExist:
        category = Category.objects.first()
        print(f"✅ Using first available category: {category.name}")
    
    # Get or create a supplier
    supplier = Supplier.objects.first()
    if not supplier:
        print("❌ No supplier found. Please create a supplier first.")
        return
    
    # Create the base product
    product = Product.objects.create(
        name="iPhone 15 Pro",
        description="آیفون ۱۵ پرو با پردازنده A17 Pro و دوربین فوق‌العاده",
        category=category,
        supplier=supplier,
        price_toman=45000000,  # Base price
        is_active=True,
    )
    
    print(f"✅ Created base product: {product.name} (ID: {product.id})")
    
    # Create variants with different colors and storage
    variants_data = [
        {
            'sku': 'IPHONE15PRO-BLUE-128GB',
            'attributes': {'color': 'آبی', 'storage': '۱۲۸ گیگابایت'},
            'price': 45000000,
            'stock': 25
        },
        {
            'sku': 'IPHONE15PRO-BLUE-256GB',
            'attributes': {'color': 'آبی', 'storage': '۲۵۶ گیگابایت'},
            'price': 52000000,
            'stock': 20
        },
        {
            'sku': 'IPHONE15PRO-BLUE-512GB',
            'attributes': {'color': 'آبی', 'storage': '۵۱۲ گیگابایت'},
            'price': 58000000,
            'stock': 15
        },
        {
            'sku': 'IPHONE15PRO-BLACK-128GB',
            'attributes': {'color': 'مشکی', 'storage': '۱۲۸ گیگابایت'},
            'price': 45000000,
            'stock': 30
        },
        {
            'sku': 'IPHONE15PRO-BLACK-256GB',
            'attributes': {'color': 'مشکی', 'storage': '۲۵۶ گیگابایت'},
            'price': 52000000,
            'stock': 25
        },
        {
            'sku': 'IPHONE15PRO-BLACK-512GB',
            'attributes': {'color': 'مشکی', 'storage': '۵۱۲ گیگابایت'},
            'price': 58000000,
            'stock': 18
        },
        {
            'sku': 'IPHONE15PRO-WHITE-128GB',
            'attributes': {'color': 'سفید', 'storage': '۱۲۸ گیگابایت'},
            'price': 45000000,
            'stock': 22
        },
        {
            'sku': 'IPHONE15PRO-WHITE-256GB',
            'attributes': {'color': 'سفید', 'storage': '۲۵۶ گیگابایت'},
            'price': 52000000,
            'stock': 20
        },
        {
            'sku': 'IPHONE15PRO-GOLD-512GB',
            'attributes': {'color': 'طلایی', 'storage': '۵۱۲ گیگابایت'},
            'price': 60000000,  # Premium color, higher price
            'stock': 12
        }
    ]
    
    created_variants = []
    
    for variant_data in variants_data:
        variant = ProductVariant.objects.create(
            product=product,
            sku=variant_data['sku'],
            attributes=variant_data['attributes'],
            price_toman=variant_data['price'],
            stock_quantity=variant_data['stock'],
            is_active=True
        )
        created_variants.append(variant)
        
        # Create display name
        attr_display = ' - '.join(variant_data['attributes'].values())
        print(f"  ✅ Created variant: {variant.sku} ({attr_display}) - {variant_data['price']:,} تومان - موجودی: {variant_data['stock']}")
    
    print(f"\n🎉 Successfully created product '{product.name}' with {len(created_variants)} variants!")
    print(f"📱 Product ID: {product.id}")
    print(f"🔗 Admin URL: http://127.0.0.1:8000/admin/shop/product/{product.id}/change/")
    print(f"🔗 Category Attributes: http://127.0.0.1:8000/shop/manage/category/{category.id}/attributes/")
    
    # Display summary
    print("\n📊 Variant Summary:")
    colors = set()
    storages = set()
    total_stock = 0
    price_range = []
    
    for variant in created_variants:
        colors.add(variant.attributes.get('color', 'N/A'))
        storages.add(variant.attributes.get('storage', 'N/A'))
        total_stock += variant.stock_quantity
        price_range.append(variant.price_toman)
    
    print(f"  🎨 Available Colors: {', '.join(colors)}")
    print(f"  💾 Available Storage: {', '.join(storages)}")
    print(f"  📦 Total Stock: {total_stock} units")
    print(f"  💰 Price Range: {min(price_range):,} - {max(price_range):,} تومان")
    
    return product, created_variants

if __name__ == '__main__':
    try:
        product, variants = create_demo_product_with_variants()
        print(f"\n✨ Demo completed! Check the admin panel to see your product with variants.")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()


