from django.core.management.base import BaseCommand, CommandError
from suppliers.models import SupplierUser, Supplier, SupplierInvitation
from django.utils import timezone
from datetime import timedelta


class Command(BaseCommand):
    help = 'Send invitation to join a supplier'

    def add_arguments(self, parser):
        parser.add_argument('--supplier-id', type=int, required=True, help='Supplier ID')
        parser.add_argument('--email', type=str, required=True, help='Email to invite')
        parser.add_argument('--role', type=str, choices=['admin', 'staff'], default='staff', help='Role for the invited user')
        parser.add_argument('--permissions', type=str, nargs='+', help='Permissions to grant')
        parser.add_argument('--expires-days', type=int, default=7, help='Days until invitation expires')

    def handle(self, *args, **options):
        try:
            # Get supplier
            supplier = Supplier.objects.get(id=options['supplier_id'])
            
            # Get a supplier admin to send the invitation
            admin_role = SupplierRole.objects.filter(
                supplier=supplier,
                role='admin',
                is_active=True
            ).first()
            
            if not admin_role:
                raise CommandError(f'No active admin found for supplier "{supplier.name}"')
            
            # Set default permissions based on role
            permissions = options.get('permissions', [])
            if not permissions:
                if options['role'] == 'admin':
                    permissions = [
                        'manage_stores',
                        'manage_products',
                        'manage_orders',
                        'manage_staff',
                        'view_analytics',
                        'manage_inventory'
                    ]
                else:
                    permissions = ['manage_products', 'manage_orders']

            # Create invitation
            invitation = SupplierInvitation.objects.create(
                supplier=supplier,
                invited_by=admin_role.user,
                email=options['email'],
                role=options['role'],
                permissions=permissions,
                expires_at=timezone.now() + timedelta(days=options['expires_days'])
            )

            # Send invitation email
            invitation.send_invitation_email()

            self.stdout.write(
                self.style.SUCCESS(
                    f'Successfully sent invitation to "{options["email"]}" for supplier "{supplier.name}"'
                )
            )
            self.stdout.write(f'Invitation token: {invitation.token}')
            self.stdout.write(f'Expires at: {invitation.expires_at}')

        except Supplier.DoesNotExist:
            raise CommandError(f'Supplier with ID {options["supplier_id"]} not found')
        except Exception as e:
            raise CommandError(f'Error sending invitation: {str(e)}')
