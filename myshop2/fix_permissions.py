import os
import sys
import django

# Set up Django environment
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from django.contrib.auth import get_user_model
from myshop.suppliers.models import SupplierAdmin, Supplier

User = get_user_model()

def fix_superuser_permissions():
    """Fix permissions for superusers"""
    username = input("Enter the username of the superuser to fix: ")
    
    try:
        user = User.objects.get(username=username)
        print(f"User found: {user.username}")
        
        # Set superuser flag
        user.is_superuser = True
        user.is_staff = True
        user.save()
        print(f"Updated user {user.username}: is_superuser={user.is_superuser}, is_staff={user.is_staff}")
        
        # Check if user already has a supplier admin record
        has_supplier_admin = SupplierAdmin.objects.filter(user=user).exists()
        if has_supplier_admin:
            print(f"User already has a SupplierAdmin record")
        else:
            print("No SupplierAdmin record found. Creating one...")
            
            # Check if there's an existing supplier to connect with
            suppliers = Supplier.objects.all()
            if suppliers:
                print("Available suppliers:")
                for i, supplier in enumerate(suppliers):
                    print(f"{i+1}. {supplier.name} ({supplier.email})")
                
                choice = input("Select a supplier (number) or press Enter to create a new one: ")
                if choice and choice.isdigit() and 1 <= int(choice) <= len(suppliers):
                    supplier = suppliers[int(choice)-1]
                else:
                    # Create a new supplier
                    supplier_name = input("Enter new supplier name (or press Enter to use username): ")
                    if not supplier_name:
                        supplier_name = f"{user.username}'s Store"
                    
                    supplier_email = input("Enter supplier email (or press Enter to use user email): ")
                    if not supplier_email:
                        supplier_email = user.email
                    
                    supplier = Supplier.objects.create(
                        name=supplier_name,
                        email=supplier_email,
                        is_active=True
                    )
                    print(f"Created new supplier: {supplier.name}")
                
                # Create SupplierAdmin record
                supplier_admin = SupplierAdmin.objects.create(
                    user=user,
                    supplier=supplier,
                    is_primary=True,
                    role='admin'
                )
                print(f"Created SupplierAdmin record connecting {user.username} to {supplier.name}")
                
                # Also set is_supplier_admin flag
                user.is_supplier_admin = True
                user.save()
                print(f"Set is_supplier_admin=True for {user.username}")
        
        print("\nPermission fix completed. Try logging in again.")
                
    except User.DoesNotExist:
        print(f"No user found with username: {username}")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    fix_superuser_permissions() 