import os
import sys
import django

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop2.myshop.settings')
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
django.setup()

from django.contrib.auth import get_user_model
from myshop.suppliers.models import SupplierAdmin, Supplier

User = get_user_model()

def main():
    # Get all users
    print("All users:")
    for user in User.objects.all():
        is_supplier = SupplierAdmin.objects.filter(user=user).exists()
        print(f"Username: {user.username}, Email: {user.email}, Is superuser: {user.is_superuser}, Is supplier admin: {user.is_supplier_admin}, Has SupplierAdmin record: {is_supplier}")
        if is_supplier:
            supplier_admin = SupplierAdmin.objects.get(user=user)
            print(f"   Supplier: {supplier_admin.supplier.name if supplier_admin.supplier else 'None'}, Is primary: {supplier_admin.is_primary}")
    
    print("\n---------------\n")
    
    # Get all supplier admins
    print("All SupplierAdmin records:")
    for supplier_admin in SupplierAdmin.objects.all():
        print(f"User: {supplier_admin.user.username}, Supplier: {supplier_admin.supplier.name if supplier_admin.supplier else 'None'}, Is primary: {supplier_admin.is_primary}")
    
    print("\n---------------\n")
    
    # Get all suppliers
    print("All Suppliers:")
    for supplier in Supplier.objects.all():
        print(f"Name: {supplier.name}, Email: {supplier.email}, Admins: {SupplierAdmin.objects.filter(supplier=supplier).count()}")

if __name__ == "__main__":
    main() 