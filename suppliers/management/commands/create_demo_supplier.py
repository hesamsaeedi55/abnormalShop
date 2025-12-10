from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from suppliers.models import SupplierUser, Supplier, Store, SupplierRole
from django.db import transaction


class Command(BaseCommand):
    help = 'Create a demo supplier for testing'

    def handle(self, *args, **options):
        try:
            with transaction.atomic():
                # Create demo supplier
                supplier = Supplier.objects.create(
                    name="Demo Supplier Company",
                    contact_person="John Admin",
                    email="admin@demosupplier.com",
                    phone="+1234567890",
                    address_line1="123 Business St",
                    city="New York",
                    state="NY",
                    country="USA",
                    postal_code="10001",
                    status='active',
                    is_active=True
                )

                # Create admin user
                admin_user = SupplierUser.objects.create_user(
                    email="admin@demosupplier.com",
                    password="demo123",
                    first_name="John",
                    last_name="Admin",
                    is_active=True,
                    is_email_verified=True
                )

                # Create admin role
                admin_role = SupplierRole.objects.create(
                    user=admin_user,
                    supplier=supplier,
                    role='admin',
                    permissions=[
                        'manage_stores',
                        'manage_products',
                        'manage_orders',
                        'manage_staff',
                        'view_analytics',
                        'manage_inventory'
                    ],
                    is_active=True
                )

                # Create demo store
                store = Store.objects.create(
                    supplier=supplier,
                    name="Demo Main Store",
                    contact_email="admin@demosupplier.com",
                    address_line1="123 Business St",
                    city="New York",
                    state="NY",
                    country="USA",
                    postal_code="10001",
                    status='active',
                    is_active=True
                )

                # Give admin access to the store
                admin_role.accessible_stores.add(store)

                self.stdout.write(
                    self.style.SUCCESS(
                        f'✅ Demo supplier created successfully!\n'
                        f'   Supplier: {supplier.name}\n'
                        f'   Admin Email: {admin_user.email}\n'
                        f'   Admin Password: demo123\n'
                        f'   Store: {store.name}\n\n'
                        f'🌐 Access URLs:\n'
                        f'   Landing Page: http://localhost:8000/suppliers/web/\n'
                        f'   Login Page: http://localhost:8000/suppliers/web/login/\n'
                        f'   Dashboard: http://localhost:8000/suppliers/web/dashboard/\n'
                    )
                )

        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'❌ Error creating demo supplier: {str(e)}')
            )
