from django.core.management.base import BaseCommand, CommandError
from suppliers.models import SupplierUser, Supplier, Store, SupplierRole, SupplierInvitation
from django.db import transaction
from django.utils import timezone


class Command(BaseCommand):
    help = 'List all suppliers and their details'

    def add_arguments(self, parser):
        parser.add_argument('--supplier-id', type=int, help='Show details for specific supplier')
        parser.add_argument('--include-users', action='store_true', help='Include user details')
        parser.add_argument('--include-stores', action='store_true', help='Include store details')
        parser.add_argument('--include-invitations', action='store_true', help='Include pending invitations')

    def handle(self, *args, **options):
        if options.get('supplier_id'):
            try:
                supplier = Supplier.objects.get(id=options['supplier_id'])
                self.display_supplier_details(supplier, options)
            except Supplier.DoesNotExist:
                raise CommandError(f'Supplier with ID {options["supplier_id"]} not found')
        else:
            suppliers = Supplier.objects.all().order_by('-created_at')
            self.stdout.write(f'Found {suppliers.count()} suppliers:\n')
            
            for supplier in suppliers:
                self.stdout.write(f'ID: {supplier.id} | Name: {supplier.name} | Status: {supplier.status} | Created: {supplier.created_at.date()}')
                
                if options.get('include_users'):
                    users = supplier.get_all_users()
                    self.stdout.write(f'  Users: {users.count()}')
                    for user in users:
                        roles = user.supplier_roles.filter(supplier=supplier)
                        role_names = [role.role for role in roles]
                        self.stdout.write(f'    - {user.email} ({", ".join(role_names)})')
                
                if options.get('include_stores'):
                    stores = supplier.stores.all()
                    self.stdout.write(f'  Stores: {stores.count()}')
                    for store in stores:
                        self.stdout.write(f'    - {store.name} ({store.status})')
                
                if options.get('include_invitations'):
                    invitations = supplier.invitations.filter(status='pending')
                    self.stdout.write(f'  Pending Invitations: {invitations.count()}')
                    for invitation in invitations:
                        self.stdout.write(f'    - {invitation.email} ({invitation.role}) - Expires: {invitation.expires_at.date()}')
                
                self.stdout.write('')

    def display_supplier_details(self, supplier, options):
        self.stdout.write(f'\n=== Supplier Details ===')
        self.stdout.write(f'ID: {supplier.id}')
        self.stdout.write(f'Name: {supplier.name}')
        self.stdout.write(f'Slug: {supplier.slug}')
        self.stdout.write(f'Status: {supplier.status}')
        self.stdout.write(f'Contact Person: {supplier.contact_person}')
        self.stdout.write(f'Email: {supplier.email}')
        self.stdout.write(f'Phone: {supplier.phone}')
        self.stdout.write(f'Address: {supplier.address_line1}, {supplier.city}, {supplier.country}')
        self.stdout.write(f'Created: {supplier.created_at}')
        self.stdout.write(f'Updated: {supplier.updated_at}')
        
        if options.get('include_users'):
            self.stdout.write(f'\n=== Users ===')
            users = supplier.get_all_users()
            for user in users:
                roles = user.supplier_roles.filter(supplier=supplier)
                self.stdout.write(f'Email: {user.email}')
                self.stdout.write(f'Name: {user.get_full_name()}')
                self.stdout.write(f'Active: {user.is_active}')
                for role in roles:
                    self.stdout.write(f'Role: {role.role} (Permissions: {", ".join(role.permissions)})')
                self.stdout.write('')
        
        if options.get('include_stores'):
            self.stdout.write(f'\n=== Stores ===')
            stores = supplier.stores.all()
            for store in stores:
                self.stdout.write(f'Name: {store.name}')
                self.stdout.write(f'Slug: {store.slug}')
                self.stdout.write(f'Status: {store.status}')
                self.stdout.write(f'Type: {store.store_type}')
                self.stdout.write(f'Currency: {store.currency}')
                self.stdout.write(f'Contact Email: {store.contact_email}')
                self.stdout.write('')
        
        if options.get('include_invitations'):
            self.stdout.write(f'\n=== Invitations ===')
            invitations = supplier.invitations.all()
            for invitation in invitations:
                self.stdout.write(f'Email: {invitation.email}')
                self.stdout.write(f'Role: {invitation.role}')
                self.stdout.write(f'Status: {invitation.status}')
                self.stdout.write(f'Expires: {invitation.expires_at}')
                self.stdout.write(f'Invited By: {invitation.invited_by.email}')
                self.stdout.write('')
