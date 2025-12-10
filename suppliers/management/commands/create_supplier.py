from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from suppliers.models import SupplierUser, Supplier, Store, SupplierRole, SupplierInvitation
from django.db import transaction
import uuid


class Command(BaseCommand):
    help = 'Create a new supplier with admin user'

    def add_arguments(self, parser):
        parser.add_argument('--name', type=str, required=True, help='Supplier name')
        parser.add_argument('--email', type=str, required=True, help='Admin user email')
        parser.add_argument('--password', type=str, required=True, help='Admin user password')
        parser.add_argument('--first-name', type=str, required=True, help='Admin user first name')
        parser.add_argument('--last-name', type=str, required=True, help='Admin user last name')
        parser.add_argument('--phone', type=str, help='Supplier phone number')
        parser.add_argument('--contact-person', type=str, help='Contact person name')
        parser.add_argument('--address', type=str, help='Supplier address')
        parser.add_argument('--city', type=str, default='Tehran', help='Supplier city')
        parser.add_argument('--country', type=str, default='Iran', help='Supplier country')
        parser.add_argument('--create-store', action='store_true', help='Create a default store')

    def handle(self, *args, **options):
        try:
            with transaction.atomic():
                # Create supplier
                supplier = Supplier.objects.create(
                    name=options['name'],
                    contact_person=options.get('contact_person', options['first_name'] + ' ' + options['last_name']),
                    email=options['email'],
                    phone=options.get('phone', ''),
                    address_line1=options.get('address', ''),
                    city=options['city'],
                    country=options['country'],
                    status='active',
                    is_active=True
                )

                # Create admin user
                admin_user = SupplierUser.objects.create_user(
                    email=options['email'],
                    password=options['password'],
                    first_name=options['first_name'],
                    last_name=options['last_name'],
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

                # Create default store if requested
                if options.get('create_store'):
                    store = Store.objects.create(
                        supplier=supplier,
                        name=f"{supplier.name} Main Store",
                        contact_email=options['email'],
                        address_line1=options.get('address', ''),
                        city=options['city'],
                        country=options['country'],
                        status='active',
                        is_active=True
                    )
                    
                    # Give admin access to the store
                    admin_role.accessible_stores.add(store)

                self.stdout.write(
                    self.style.SUCCESS(
                        f'Successfully created supplier "{supplier.name}" with admin user "{admin_user.email}"'
                    )
                )
                
                if options.get('create_store'):
                    self.stdout.write(
                        self.style.SUCCESS(f'Created default store: {store.name}')
                    )

        except Exception as e:
            raise CommandError(f'Error creating supplier: {str(e)}')
