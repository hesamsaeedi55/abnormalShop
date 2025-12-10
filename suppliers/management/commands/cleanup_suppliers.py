from django.core.management.base import BaseCommand, CommandError
from suppliers.models import SupplierUser, SupplierInvitation
from django.utils import timezone


class Command(BaseCommand):
    help = 'Clean up expired invitations and inactive users'

    def add_arguments(self, parser):
        parser.add_argument('--dry-run', action='store_true', help='Show what would be cleaned without actually doing it')
        parser.add_argument('--expired-invitations', action='store_true', help='Clean expired invitations')
        parser.add_argument('--inactive-users', action='store_true', help='Clean inactive users')
        parser.add_argument('--all', action='store_true', help='Clean all types')

    def handle(self, *args, **options):
        if not any([options.get('expired_invitations'), options.get('inactive_users'), options.get('all')]):
            self.stdout.write(self.style.WARNING('Please specify what to clean. Use --help for options.'))
            return

        dry_run = options.get('dry_run', False)
        cleaned_count = 0

        if options.get('expired_invitations') or options.get('all'):
            cleaned_count += self.clean_expired_invitations(dry_run)

        if options.get('inactive_users') or options.get('all'):
            cleaned_count += self.clean_inactive_users(dry_run)

        if dry_run:
            self.stdout.write(self.style.WARNING(f'DRY RUN: Would clean {cleaned_count} items'))
        else:
            self.stdout.write(self.style.SUCCESS(f'Successfully cleaned {cleaned_count} items'))

    def clean_expired_invitations(self, dry_run=False):
        """Clean expired invitations"""
        expired_invitations = SupplierInvitation.objects.filter(
            status='pending',
            expires_at__lt=timezone.now()
        )
        
        count = expired_invitations.count()
        
        if count > 0:
            if dry_run:
                self.stdout.write(f'Would mark {count} expired invitations as expired')
                for invitation in expired_invitations:
                    self.stdout.write(f'  - {invitation.email} ({invitation.supplier.name}) - Expired: {invitation.expires_at}')
            else:
                expired_invitations.update(status='expired')
                self.stdout.write(self.style.SUCCESS(f'Marked {count} expired invitations as expired'))
        
        return count

    def clean_inactive_users(self, dry_run=False):
        """Clean inactive users (users with no active roles)"""
        inactive_users = SupplierUser.objects.filter(
            supplier_roles__isnull=True
        ).distinct()
        
        count = inactive_users.count()
        
        if count > 0:
            if dry_run:
                self.stdout.write(f'Would deactivate {count} users with no supplier roles')
                for user in inactive_users:
                    self.stdout.write(f'  - {user.email} ({user.get_full_name()})')
            else:
                inactive_users.update(is_active=False)
                self.stdout.write(self.style.SUCCESS(f'Deactivated {count} users with no supplier roles'))
        
        return count
