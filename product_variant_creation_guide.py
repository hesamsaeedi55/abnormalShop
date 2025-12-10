"""
🔥 COMPLETE GUIDE: Creating Products with Variants

This shows you EXACTLY how to insert products with their variants
into the database using different methods.
"""

from django.db import transaction
from shop.models import (
    Product, ProductVariant, VariantAttribute, 
    Attribute, NewAttributeValue, Category
)


# ========================================
# METHOD 1: Programmatic Creation (Python Code)
# ========================================

def create_product_with_variants_programmatically():
    """
    🔥 Create a complete product with all its variants programmatically
    Perfect for scripts, data migration, or bulk creation
    """
    
    print("🔥 METHOD 1: Programmatic Creation")
    
    with transaction.atomic():
        # Step 1: Create the base product
        product = Product.objects.create(
            name="Classic T-Shirt",
            slug="classic-tshirt",
            description="Comfortable cotton t-shirt available in multiple colors and sizes",
            category_id=1,  # Your clothing category
            brand="YourBrand",
            is_active=True
        )
        
        # Step 2: Get attributes (assume they exist)
        color_attr = Attribute.objects.get(key="color")
        size_attr = Attribute.objects.get(key="size")
        
        # Step 3: Get attribute values
        red = NewAttributeValue.objects.get(attribute=color_attr, value="Red")
        blue = NewAttributeValue.objects.get(attribute=color_attr, value="Blue")
        black = NewAttributeValue.objects.get(attribute=color_attr, value="Black")
        
        size_s = NewAttributeValue.objects.get(attribute=size_attr, value="S")
        size_m = NewAttributeValue.objects.get(attribute=size_attr, value="M")
        size_l = NewAttributeValue.objects.get(attribute=size_attr, value="L")
        
        # Step 4: Define all variants with their specific data
        variant_combinations = [
            {"color": red, "size": size_s, "price": 250000, "stock": 30},
            {"color": red, "size": size_m, "price": 250000, "stock": 50},
            {"color": red, "size": size_l, "price": 250000, "stock": 40},
            
            {"color": blue, "size": size_s, "price": 250000, "stock": 25},
            {"color": blue, "size": size_m, "price": 250000, "stock": 45},
            {"color": blue, "size": size_l, "price": 250000, "stock": 35},
            
            {"color": black, "size": size_s, "price": 280000, "stock": 20},  # Black premium
            {"color": black, "size": size_m, "price": 280000, "stock": 40},
            {"color": black, "size": size_l, "price": 280000, "stock": 30},
        ]
        
        # Step 5: Create all variants
        created_variants = []
        for i, combo in enumerate(variant_combinations):
            # Generate SKU
            sku = f"TSHIRT-{combo['color'].value.upper()}-{combo['size'].value}"
            
            # Create variant
            variant = ProductVariant.objects.create(
                product=product,
                sku=sku,
                variant_name=f"{combo['color'].value} - {combo['size'].value}",
                price_toman=combo['price'],
                stock_quantity=combo['stock'],
                is_active=True,
                is_default=(i == 0)  # First variant is default
            )
            
            # Link attributes to variant
            VariantAttribute.objects.create(variant=variant, attribute_value=combo['color'])
            VariantAttribute.objects.create(variant=variant, attribute_value=combo['size'])
            
            created_variants.append(variant)
            print(f"✅ Created: {sku} - {combo['price']:,} تومان - {combo['stock']} units")
        
        print(f"🎉 Product '{product.name}' created with {len(created_variants)} variants!")
        return product, created_variants


# ========================================
# METHOD 2: Helper Functions for Easy Creation
# ========================================

class ProductVariantCreator:
    """
    🔥 Helper class to make product+variant creation super easy
    """
    
    def __init__(self, product_data):
        self.product_data = product_data
        self.variants_data = []
    
    def add_variant(self, attributes_dict, price_toman, stock_quantity, **kwargs):
        """
        Add a variant with specific attributes
        
        Example:
        creator.add_variant(
            attributes_dict={"color": "Red", "size": "M"},
            price_toman=250000,
            stock_quantity=50
        )
        """
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
                    attribute = Attribute.objects.get(key=attr_key)
                    attr_value_obj = NewAttributeValue.objects.get(
                        attribute=attribute, 
                        value=attr_value
                    )
                    VariantAttribute.objects.create(
                        variant=variant, 
                        attribute_value=attr_value_obj
                    )
                
                created_variants.append(variant)
            
            return product, created_variants


def create_product_easy_way():
    """
    🔥 Example using the helper class - SUPER EASY!
    """
    
    print("🔥 METHOD 2: Easy Helper Class")
    
    # Create iPhone with variants
    creator = ProductVariantCreator({
        'name': 'iPhone 15 Pro',
        'slug': 'iphone-15-pro',
        'description': 'Latest iPhone with Pro features',
        'category_id': 2,  # Electronics category
        'brand': 'Apple',
        'is_active': True
    })
    
    # Add all variants easily
    creator.add_variant({"color": "Blue", "storage": "128GB"}, 35000000, 15)
    creator.add_variant({"color": "Blue", "storage": "256GB"}, 38000000, 12)
    creator.add_variant({"color": "Blue", "storage": "512GB"}, 42000000, 8)
    
    creator.add_variant({"color": "Black", "storage": "128GB"}, 35500000, 10)  # Black premium
    creator.add_variant({"color": "Black", "storage": "256GB"}, 38500000, 8)
    creator.add_variant({"color": "Black", "storage": "512GB"}, 42500000, 5)
    
    creator.add_variant({"color": "White", "storage": "128GB"}, 35000000, 12)
    creator.add_variant({"color": "White", "storage": "256GB"}, 38000000, 9)
    creator.add_variant({"color": "White", "storage": "512GB"}, 42000000, 6)
    
    # Create everything at once
    product, variants = creator.create()
    
    print(f"✅ Created '{product.name}' with {len(variants)} variants")
    for variant in variants:
        print(f"  • {variant.sku}: {variant.price_toman:,} تومان ({variant.stock_quantity} units)")
    
    return product, variants


# ========================================
# METHOD 3: Bulk Creation from Data
# ========================================

def create_products_from_data(products_data):
    """
    🔥 Create multiple products with variants from structured data
    Perfect for importing from Excel, CSV, or external systems
    """
    
    print("🔥 METHOD 3: Bulk Creation from Data")
    
    created_products = []
    
    for product_data in products_data:
        with transaction.atomic():
            # Create base product
            product = Product.objects.create(
                name=product_data['name'],
                slug=product_data['slug'],
                description=product_data.get('description', ''),
                category_id=product_data['category_id'],
                brand=product_data.get('brand', ''),
                is_active=True
            )
            
            # Create variants
            for variant_data in product_data['variants']:
                variant = ProductVariant.objects.create(
                    product=product,
                    sku=variant_data['sku'],
                    variant_name=variant_data.get('name', ''),
                    price_toman=variant_data['price'],
                    stock_quantity=variant_data['stock'],
                    is_active=True,
                    is_default=variant_data.get('is_default', False)
                )
                
                # Add attributes
                for attr_key, attr_value in variant_data['attributes'].items():
                    attribute = Attribute.objects.get(key=attr_key)
                    attr_value_obj = NewAttributeValue.objects.get(
                        attribute=attribute, 
                        value=attr_value
                    )
                    VariantAttribute.objects.create(
                        variant=variant, 
                        attribute_value=attr_value_obj
                    )
                
                print(f"✅ Created variant: {variant.sku}")
            
            created_products.append(product)
            print(f"🎉 Product '{product.name}' created with {product.variants.count()} variants")
    
    return created_products


def bulk_creation_example():
    """Example data structure for bulk creation"""
    
    products_data = [
        {
            'name': 'Running Shoes',
            'slug': 'running-shoes',
            'description': 'Professional running shoes',
            'category_id': 1,
            'brand': 'Nike',
            'variants': [
                {
                    'sku': 'SHOES-BLACK-40',
                    'name': 'Black - Size 40',
                    'price': 2500000,
                    'stock': 20,
                    'attributes': {'color': 'Black', 'size': '40'},
                    'is_default': True
                },
                {
                    'sku': 'SHOES-BLACK-41',
                    'name': 'Black - Size 41',
                    'price': 2500000,
                    'stock': 25,
                    'attributes': {'color': 'Black', 'size': '41'}
                },
                {
                    'sku': 'SHOES-WHITE-40',
                    'name': 'White - Size 40',
                    'price': 2500000,
                    'stock': 15,
                    'attributes': {'color': 'White', 'size': '40'}
                },
                {
                    'sku': 'SHOES-WHITE-41',
                    'name': 'White - Size 41',
                    'price': 2500000,
                    'stock': 18,
                    'attributes': {'color': 'White', 'size': '41'}
                }
            ]
        },
        {
            'name': 'Wireless Headphones',
            'slug': 'wireless-headphones',
            'description': 'Premium wireless headphones',
            'category_id': 2,
            'brand': 'Sony',
            'variants': [
                {
                    'sku': 'HEADPHONES-BLACK',
                    'name': 'Black',
                    'price': 1800000,
                    'stock': 30,
                    'attributes': {'color': 'Black'},
                    'is_default': True
                },
                {
                    'sku': 'HEADPHONES-WHITE',
                    'name': 'White',
                    'price': 1800000,
                    'stock': 25,
                    'attributes': {'color': 'White'}
                },
                {
                    'sku': 'HEADPHONES-SILVER',
                    'name': 'Silver',
                    'price': 1900000,  # Silver costs more
                    'stock': 15,
                    'attributes': {'color': 'Silver'}
                }
            ]
        }
    ]
    
    return create_products_from_data(products_data)


# ========================================
# METHOD 4: Django Management Command
# ========================================

def create_management_command():
    """
    🔥 Create a Django management command for product creation
    Save this as: shop/management/commands/create_product_variants.py
    """
    
    command_code = '''
from django.core.management.base import BaseCommand
from django.db import transaction
import json
from shop.models import Product, ProductVariant, VariantAttribute, Attribute, NewAttributeValue

class Command(BaseCommand):
    help = 'Create product with variants from JSON data'
    
    def add_arguments(self, parser):
        parser.add_argument('--json-file', type=str, help='JSON file with product data')
        parser.add_argument('--product-name', type=str, help='Product name')
    
    def handle(self, *args, **options):
        if options['json_file']:
            self.create_from_json(options['json_file'])
        elif options['product_name']:
            self.create_sample_product(options['product_name'])
        else:
            self.stdout.write('Please provide --json-file or --product-name')
    
    def create_from_json(self, json_file):
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        with transaction.atomic():
            product = Product.objects.create(**data['product'])
            
            for variant_data in data['variants']:
                variant = ProductVariant.objects.create(
                    product=product,
                    **variant_data['variant_info']
                )
                
                for attr_key, attr_value in variant_data['attributes'].items():
                    attribute = Attribute.objects.get(key=attr_key)
                    attr_value_obj = NewAttributeValue.objects.get(
                        attribute=attribute, value=attr_value
                    )
                    VariantAttribute.objects.create(
                        variant=variant, attribute_value=attr_value_obj
                    )
        
        self.stdout.write(f"✅ Created product: {product.name}")
    
    def create_sample_product(self, name):
        # Create a sample product with variants
        self.stdout.write(f"Creating sample product: {name}")
        # Implementation here...
'''
    
    print("📁 Save this as: shop/management/commands/create_product_variants.py")
    print(command_code)


# ========================================
# USAGE EXAMPLES
# ========================================

def demonstrate_all_methods():
    """
    🔥 Demonstrate all creation methods
    """
    
    print("🔥 DEMONSTRATING ALL PRODUCT+VARIANT CREATION METHODS")
    print("=" * 60)
    
    # Method 1: Programmatic
    print("\n1️⃣ PROGRAMMATIC CREATION:")
    create_product_with_variants_programmatically()
    
    # Method 2: Helper class
    print("\n2️⃣ EASY HELPER CLASS:")
    create_product_easy_way()
    
    # Method 3: Bulk creation
    print("\n3️⃣ BULK CREATION:")
    bulk_creation_example()
    
    # Method 4: Management command
    print("\n4️⃣ MANAGEMENT COMMAND:")
    create_management_command()
    
    print("\n🎉 ALL METHODS DEMONSTRATED!")
    print("Choose the method that works best for your use case.")


# ========================================
# QUICK START FUNCTIONS
# ========================================

def quick_create_tshirt():
    """🚀 Quick function to create a T-shirt with variants"""
    return create_product_easy_way()

def quick_create_phone():
    """🚀 Quick function to create a phone with variants"""
    creator = ProductVariantCreator({
        'name': 'Samsung Galaxy S24',
        'slug': 'samsung-galaxy-s24',
        'description': 'Latest Samsung flagship phone',
        'category_id': 2,
        'brand': 'Samsung',
        'is_active': True
    })
    
    # Add variants
    for color in ['Black', 'White', 'Blue']:
        for storage in ['128GB', '256GB']:
            price = 25000000 if storage == '128GB' else 28000000
            stock = 15 if color == 'Black' else 10
            creator.add_variant(
                {"color": color, "storage": storage}, 
                price, 
                stock
            )
    
    return creator.create()


if __name__ == "__main__":
    # Quick test
    demonstrate_all_methods()
'''

USAGE INSTRUCTIONS:

1. PROGRAMMATIC CREATION (for scripts):
   product, variants = create_product_with_variants_programmatically()

2. EASY CREATION (recommended):
   creator = ProductVariantCreator(product_data)
   creator.add_variant({"color": "Red", "size": "M"}, 250000, 50)
   creator.add_variant({"color": "Blue", "size": "L"}, 250000, 30)
   product, variants = creator.create()

3. BULK CREATION (for imports):
   products = bulk_creation_example()

4. MANAGEMENT COMMAND:
   python manage.py create_product_variants --product-name "Test Product"

Choose the method that fits your workflow!
'''
