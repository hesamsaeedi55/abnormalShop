"""
🔥 DJANGO MANAGEMENT COMMAND for Creating Products with Variants

Save this as: shop/management/commands/create_product_with_variants.py

Usage:
python manage.py create_product_with_variants --help
python manage.py create_product_with_variants --name "iPhone 15" --category 2
python manage.py create_product_with_variants --json-file products.json
"""

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
import json
from shop.models import (
    Product, ProductVariant, VariantAttribute, 
    Attribute, NewAttributeValue, Category
)


class Command(BaseCommand):
    help = 'Create products with variants from various sources'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--name',
            type=str,
            help='Product name for quick creation'
        )
        
        parser.add_argument(
            '--category',
            type=int,
            help='Category ID for the product'
        )
        
        parser.add_argument(
            '--json-file',
            type=str,
            help='JSON file containing product and variant data'
        )
        
        parser.add_argument(
            '--sample',
            action='store_true',
            help='Create sample products with variants'
        )
        
        parser.add_argument(
            '--interactive',
            action='store_true',
            help='Interactive mode for creating products'
        )
    
    def handle(self, *args, **options):
        if options['sample']:
            self.create_sample_products()
        elif options['json_file']:
            self.create_from_json(options['json_file'])
        elif options['name'] and options['category']:
            self.create_quick_product(options['name'], options['category'])
        elif options['interactive']:
            self.interactive_creation()
        else:
            self.print_help()
    
    def create_sample_products(self):
        """Create sample products with variants"""
        
        self.stdout.write("🔥 Creating sample products with variants...")
        
        sample_products = [
            {
                'product': {
                    'name': 'Classic T-Shirt',
                    'slug': 'classic-tshirt',
                    'description': 'Comfortable cotton t-shirt',
                    'category_id': 1,
                    'brand': 'Fashion Brand'
                },
                'variants': [
                    {'sku': 'TSHIRT-RED-S', 'attributes': {'color': 'Red', 'size': 'S'}, 'price': 250000, 'stock': 30},
                    {'sku': 'TSHIRT-RED-M', 'attributes': {'color': 'Red', 'size': 'M'}, 'price': 250000, 'stock': 50},
                    {'sku': 'TSHIRT-RED-L', 'attributes': {'color': 'Red', 'size': 'L'}, 'price': 250000, 'stock': 40},
                    {'sku': 'TSHIRT-BLUE-S', 'attributes': {'color': 'Blue', 'size': 'S'}, 'price': 250000, 'stock': 25},
                    {'sku': 'TSHIRT-BLUE-M', 'attributes': {'color': 'Blue', 'size': 'M'}, 'price': 250000, 'stock': 45},
                    {'sku': 'TSHIRT-BLUE-L', 'attributes': {'color': 'Blue', 'size': 'L'}, 'price': 250000, 'stock': 35},
                ]
            },
            {
                'product': {
                    'name': 'Wireless Headphones',
                    'slug': 'wireless-headphones',
                    'description': 'Premium wireless headphones',
                    'category_id': 2,
                    'brand': 'Audio Tech'
                },
                'variants': [
                    {'sku': 'HEADPHONES-BLACK', 'attributes': {'color': 'Black'}, 'price': 1800000, 'stock': 30},
                    {'sku': 'HEADPHONES-WHITE', 'attributes': {'color': 'White'}, 'price': 1800000, 'stock': 25},
                    {'sku': 'HEADPHONES-SILVER', 'attributes': {'color': 'Silver'}, 'price': 1900000, 'stock': 15},
                ]
            }
        ]
        
        for product_data in sample_products:
            self.create_product_with_variants(product_data)
        
        self.stdout.write(
            self.style.SUCCESS(f"✅ Created {len(sample_products)} sample products!")
        )
    
    def create_from_json(self, json_file):
        """Create products from JSON file"""
        
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except FileNotFoundError:
            raise CommandError(f"File not found: {json_file}")
        except json.JSONDecodeError:
            raise CommandError(f"Invalid JSON file: {json_file}")
        
        if isinstance(data, list):
            # Multiple products
            for product_data in data:
                self.create_product_with_variants(product_data)
            
            self.stdout.write(
                self.style.SUCCESS(f"✅ Created {len(data)} products from JSON!")
            )
        else:
            # Single product
            self.create_product_with_variants(data)
            self.stdout.write(
                self.style.SUCCESS("✅ Created product from JSON!")
            )
    
    def create_quick_product(self, name, category_id):
        """Create a simple product with basic variants"""
        
        self.stdout.write(f"🔥 Creating quick product: {name}")
        
        # Check if category exists
        try:
            category = Category.objects.get(id=category_id)
        except Category.DoesNotExist:
            raise CommandError(f"Category with ID {category_id} not found")
        
        # Create basic product data
        slug = name.lower().replace(' ', '-')
        product_data = {
            'product': {
                'name': name,
                'slug': slug,
                'description': f'Great {name} with multiple options',
                'category_id': category_id,
                'brand': 'Default Brand'
            },
            'variants': [
                {
                    'sku': f"{slug.upper()}-DEFAULT",
                    'attributes': {},
                    'price': 500000,
                    'stock': 50
                }
            ]
        }
        
        product, variants = self.create_product_with_variants(product_data)
        
        self.stdout.write(
            self.style.SUCCESS(f"✅ Created quick product: {product.name}")
        )
    
    def interactive_creation(self):
        """Interactive mode for creating products"""
        
        self.stdout.write("🔥 Interactive Product Creation")
        self.stdout.write("=" * 40)
        
        # Get product info
        name = input("Product name: ")
        slug = input(f"Product slug [{name.lower().replace(' ', '-')}]: ") or name.lower().replace(' ', '-')
        description = input("Product description: ")
        
        # Show categories
        categories = Category.objects.filter(is_active=True)
        self.stdout.write("\nAvailable categories:")
        for cat in categories:
            self.stdout.write(f"  {cat.id}: {cat.name}")
        
        category_id = int(input("Category ID: "))
        brand = input("Brand: ")
        
        # Create product
        product_data = {
            'product': {
                'name': name,
                'slug': slug,
                'description': description,
                'category_id': category_id,
                'brand': brand
            },
            'variants': []
        }
        
        # Add variants
        self.stdout.write("\n🔥 Adding variants (press Enter without SKU to finish):")
        
        while True:
            sku = input("Variant SKU: ").strip()
            if not sku:
                break
            
            price = int(input("Price (Toman): "))
            stock = int(input("Stock quantity: "))
            
            # Add attributes
            attributes = {}
            self.stdout.write("Add attributes (press Enter without key to finish):")
            
            while True:
                attr_key = input("  Attribute key: ").strip()
                if not attr_key:
                    break
                
                attr_value = input(f"  {attr_key} value: ").strip()
                attributes[attr_key] = attr_value
            
            variant_data = {
                'sku': sku,
                'attributes': attributes,
                'price': price,
                'stock': stock
            }
            
            product_data['variants'].append(variant_data)
            self.stdout.write(f"  ✅ Added variant: {sku}")
        
        if not product_data['variants']:
            self.stdout.write("No variants added. Creating default variant.")
            product_data['variants'] = [{
                'sku': f"{slug.upper()}-DEFAULT",
                'attributes': {},
                'price': 500000,
                'stock': 10
            }]
        
        # Create the product
        product, variants = self.create_product_with_variants(product_data)
        
        self.stdout.write(
            self.style.SUCCESS(f"✅ Created product: {product.name} with {len(variants)} variants")
        )
    
    def create_product_with_variants(self, data):
        """Core function to create product with variants"""
        
        product_data = data['product']
        variants_data = data['variants']
        
        with transaction.atomic():
            # Create product
            product = Product.objects.create(**product_data)
            
            created_variants = []
            
            for i, variant_data in enumerate(variants_data):
                # Create variant
                variant = ProductVariant.objects.create(
                    product=product,
                    sku=variant_data['sku'],
                    variant_name=self.generate_variant_name(variant_data['attributes']),
                    price_toman=variant_data['price'],
                    stock_quantity=variant_data['stock'],
                    is_active=True,
                    is_default=(i == 0)  # First variant is default
                )
                
                # Add attributes
                for attr_key, attr_value in variant_data['attributes'].items():
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
                        self.stdout.write(
                            self.style.WARNING(
                                f"⚠️ Attribute {attr_key}={attr_value} not found, skipping"
                            )
                        )
                
                created_variants.append(variant)
                self.stdout.write(f"  ✅ Created variant: {variant.sku}")
            
            self.stdout.write(
                self.style.SUCCESS(
                    f"🎉 Product '{product.name}' created with {len(created_variants)} variants"
                )
            )
            
            return product, created_variants
    
    def generate_variant_name(self, attributes):
        """Generate variant name from attributes"""
        if not attributes:
            return "پیش‌فرض"
        
        return " - ".join(attributes.values())
    
    def print_help(self):
        """Print usage help"""
        
        help_text = """
🔥 PRODUCT WITH VARIANTS CREATION COMMAND

Usage Examples:

1. Create sample products:
   python manage.py create_product_with_variants --sample

2. Create from JSON file:
   python manage.py create_product_with_variants --json-file products.json

3. Quick product creation:
   python manage.py create_product_with_variants --name "iPhone 15" --category 2

4. Interactive creation:
   python manage.py create_product_with_variants --interactive

JSON File Format:
{
    "product": {
        "name": "Product Name",
        "slug": "product-slug",
        "description": "Product description",
        "category_id": 1,
        "brand": "Brand Name"
    },
    "variants": [
        {
            "sku": "PRODUCT-RED-M",
            "attributes": {"color": "Red", "size": "M"},
            "price": 250000,
            "stock": 50
        }
    ]
}

For multiple products, use an array of the above structure.
"""
        
        self.stdout.write(help_text)


# ========================================
# SAMPLE JSON FILE
# ========================================

sample_json = {
    "product": {
        "name": "iPhone 15 Pro",
        "slug": "iphone-15-pro",
        "description": "Latest iPhone with Pro features and advanced camera system",
        "category_id": 2,
        "brand": "Apple"
    },
    "variants": [
        {
            "sku": "IPHONE-BLUE-128GB",
            "attributes": {
                "color": "Blue",
                "storage": "128GB"
            },
            "price": 35000000,
            "stock": 15
        },
        {
            "sku": "IPHONE-BLUE-256GB",
            "attributes": {
                "color": "Blue",
                "storage": "256GB"
            },
            "price": 38000000,
            "stock": 12
        },
        {
            "sku": "IPHONE-BLACK-128GB",
            "attributes": {
                "color": "Black",
                "storage": "128GB"
            },
            "price": 35500000,
            "stock": 10
        },
        {
            "sku": "IPHONE-BLACK-256GB",
            "attributes": {
                "color": "Black",
                "storage": "256GB"
            },
            "price": 38500000,
            "stock": 8
        }
    ]
}

"""
🔥 SETUP INSTRUCTIONS:

1. Create directory: shop/management/commands/
2. Save this file as: shop/management/commands/create_product_with_variants.py
3. Create __init__.py files:
   touch shop/management/__init__.py
   touch shop/management/commands/__init__.py

4. Usage:
   python manage.py create_product_with_variants --sample
   python manage.py create_product_with_variants --interactive
   python manage.py create_product_with_variants --name "Test Product" --category 1

5. For JSON creation, save sample_json to a file and use:
   python manage.py create_product_with_variants --json-file products.json

This command makes it super easy to create products with variants!
"""
