import os
import django
import sys
from django.contrib.auth import get_user_model

# Add the project root directory to Python path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(project_root)

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop2.myshop.settings')
django.setup()

from myshop.suppliers.models import Supplier, SupplierAdmin
User = get_user_model()

def create_supplier_admin(email):
    try:
        # Get the user
        user = User.objects.get(email=email)
        
        # Check if user is already a supplier admin
        if SupplierAdmin.objects.filter(user=user).exists():
            print(f"User {email} is already a supplier admin")
            return
            
        # Get or create a supplier
        supplier, created = Supplier.objects.get_or_create(
            email=email,
            defaults={
                'name': f"{email}'s Store",
                'is_active': True
            }
        )
        
        # Create the supplier admin record
        SupplierAdmin.objects.create(
            user=user,
            supplier=supplier,
            is_primary=True,
            role='admin'
        )
        
        print(f"Successfully created supplier admin record for {email}")
        print(f"Supplier: {supplier.name}")
        
    except User.DoesNotExist:
        print(f"User with email {email} not found")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    email = input("Enter the email address of the user: ")
    create_supplier_admin(email) 