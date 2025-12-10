#!/usr/bin/env python3
"""
Script to create a t-shirt product with two color variants (red and blue)
This demonstrates the ProductVariant system working correctly.
"""

import os
import sys
import django

# Add the Django project path
sys.path.append('/Users/hesamoddinsaeedi/Desktop/best/backup copy 53/myshop2/myshop')

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from shop.models import Product, Category, ProductVariant, Supplier
from django.db import transaction

def create_tshirt_with_variants():
    """Create a t-shirt product with red and blue color variants"""
    
    try:
        with transaction.atomic():
            # Get the t-shirt category
            tshirt_category = Category.objects.get(id=1036)  # "تی شرت" category
            print(f"Found category: {tshirt_category.name}")
            
            # Get or create a default supplier
            supplier, created = Supplier.objects.get_or_create(
                name="Default Supplier",
                defaults={
                    'email': 'supplier@example.com',
                    'phone': '1234567890',
                    'address': 'Default Address',
                    'is_active': True
                }
            )
            if created:
                print(f"Created new supplier: {supplier.name}")
            else:
                print(f"Using existing supplier: {supplier.name}")
            
            # Create the main t-shirt product
            tshirt_product = Product.objects.create(
                name="تی‌شرت کلاسیک مردانه",
                description="تی‌شرت راحت و با کیفیت از جنس پنبه خالص. مناسب برای استفاده روزانه و ورزش.",
                price_toman=150000,  # 150,000 Toman
                price_usd=3.00,     # $3 USD
                category=tshirt_category,
                supplier=supplier,
                stock_quantity=0,  # Main product stock will be 0, variants have individual stock
                is_active=True,
                sku="TSHIRT-CLASSIC-MAIN",
                model="Classic Cotton T-Shirt",
                weight=200,  # 200 grams
                dimensions="70x50x2",  # Length x Width x Thickness in cm
                warranty="6 months",
                is_new_arrival=True
            )
            
            print(f"Created main product: {tshirt_product.name} (ID: {tshirt_product.id})")
            
            # Create Red variant
            red_variant = ProductVariant.objects.create(
                product=tshirt_product,
                sku="TSHIRT-RED-M",
                attributes={
                    "color": "قرمز",
                    "size": "M",
                    "material": "پنبه 100%"
                },
                price_toman=150000,  # Same price as main product
                stock_quantity=25,
                is_active=True
            )
            
            print(f"Created red variant: {red_variant.sku} (ID: {red_variant.id})")
            print(f"  - Color: {red_variant.attributes.get('color')}")
            print(f"  - Size: {red_variant.attributes.get('size')}")
            print(f"  - Stock: {red_variant.stock_quantity}")
            print(f"  - Price: {red_variant.price_toman:,} Toman")
            
            # Create Blue variant
            blue_variant = ProductVariant.objects.create(
                product=tshirt_product,
                sku="TSHIRT-BLUE-M",
                attributes={
                    "color": "آبی",
                    "size": "M", 
                    "material": "پنبه 100%"
                },
                price_toman=150000,  # Same price as main product
                stock_quantity=30,
                is_active=True
            )
            
            print(f"Created blue variant: {blue_variant.sku} (ID: {blue_variant.id})")
            print(f"  - Color: {blue_variant.attributes.get('color')}")
            print(f"  - Size: {blue_variant.attributes.get('size')}")
            print(f"  - Stock: {blue_variant.stock_quantity}")
            print(f"  - Price: {blue_variant.price_toman:,} Toman")
            
            # Verify the variants were created correctly
            variants = ProductVariant.objects.filter(product=tshirt_product)
            print(f"\n✅ Success! Created {variants.count()} variants for product '{tshirt_product.name}':")
            
            for variant in variants:
                print(f"  - {variant.sku}: {variant.attributes.get('color')} ({variant.stock_quantity} in stock)")
            
            # Test accessing variants from the product
            print(f"\n📊 Product Summary:")
            print(f"  - Main Product: {tshirt_product.name}")
            print(f"  - Category: {tshirt_product.category.name}")
            print(f"  - Total Variants: {tshirt_product.variants.count()}")
            print(f"  - Total Stock: {sum(v.stock_quantity for v in tshirt_product.variants.all())}")
            
            return tshirt_product, variants
            
    except Exception as e:
        print(f"❌ Error creating t-shirt with variants: {e}")
        import traceback
        traceback.print_exc()
        return None, None

def verify_variants_in_database():
    """Verify that the variants are properly saved in the database"""
    print("\n🔍 Verifying variants in database...")
    
    try:
        # Find our t-shirt product
        tshirt_product = Product.objects.filter(name__icontains="تی‌شرت کلاسیک").first()
        
        if not tshirt_product:
            print("❌ T-shirt product not found!")
            return False
            
        print(f"Found product: {tshirt_product.name}")
        
        # Get all variants for this product
        variants = ProductVariant.objects.filter(product=tshirt_product)
        
        if variants.count() == 0:
            print("❌ No variants found for the t-shirt!")
            return False
            
        print(f"✅ Found {variants.count()} variants:")
        
        for variant in variants:
            print(f"  - SKU: {variant.sku}")
            print(f"    Color: {variant.attributes.get('color', 'N/A')}")
            print(f"    Size: {variant.attributes.get('size', 'N/A')}")
            print(f"    Stock: {variant.stock_quantity}")
            print(f"    Price: {variant.price_toman:,} Toman")
            print(f"    Active: {variant.is_active}")
            print()
            
        return True
        
    except Exception as e:
        print(f"❌ Error verifying variants: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Creating T-shirt with Color Variants...")
    print("=" * 50)
    
    # Create the t-shirt with variants
    product, variants = create_tshirt_with_variants()
    
    if product and variants:
        print("\n" + "=" * 50)
        print("✅ T-shirt with variants created successfully!")
        
        # Verify in database
        verify_variants_in_database()
        
        print("\n🎉 Test completed! The variant system is working correctly.")
        print(f"You can now view the product '{product.name}' with its {len(variants)} color variants.")
    else:
        print("\n❌ Failed to create t-shirt with variants.")

