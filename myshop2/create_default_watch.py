import os
import django
import sys

# Add the project root directory to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set up Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop2.myshop.settings')
django.setup()

from shop.models import Category, Product, ProductAttribute
from suppliers.models import Supplier

def create_default_watch():
    try:
        # Get the existing watch category
        watch_category = Category.objects.get(name="ساعت")
        print("Found existing watch category")
        
        # Get or create a default supplier
        default_supplier, created = Supplier.objects.get_or_create(
            name="فروشگاه ساعت",
            defaults={
                'email': 'info@watchshop.com',
                'phone': '021-12345678',
                'address': 'تهران، خیابان ولیعصر',
                'is_active': True
            }
        )
        
        if created:
            print("Default supplier created successfully!")
        else:
            print("Default supplier already exists.")
        
        # Create default watch product
        default_watch, created = Product.objects.get_or_create(
            name="ساعت مچی کاسیو G-Shock",
            defaults={
                'description': "ساعت مچی مقاوم و ضد ضربه کاسیو G-Shock با طراحی مدرن و کاربردی",
                'price': 2500000,
                'supplier': default_supplier,
                'category': watch_category,
                'brand': "کاسیو",
                'model': "G-Shock DW5600",
                'sku': "CAS-GSH-001",
                'weight': 0.2,
                'stock_quantity': 10,
                'is_active': True
            }
        )
        
        if created:
            print("Default watch product created successfully!")
        else:
            print("Default watch product already exists.")
        
        # Define product attributes
        product_attributes = {
            'brand': 'کاسیو',
            'type': 'مچی',
            'body_material': 'پلاستیک',
            'band_material': 'پلاستیک',
            'water_resistance': '200 متر',
            'shock_resistance': True,
            'history': True,
            'timer': True,
            'alarm': True,
            'country_of_manufacture': 'ژاپن'
        }
        
        # Create product attributes
        for key, value in product_attributes.items():
            attr, created = ProductAttribute.objects.get_or_create(
                product=default_watch,
                key=key,
                defaults={'value': str(value)}
            )
            
            if created:
                print(f"Created attribute: {key} = {value}")
            else:
                print(f"Attribute {key} already exists")
                
    except Category.DoesNotExist:
        print("Error: Watch category not found!")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == '__main__':
    create_default_watch() 