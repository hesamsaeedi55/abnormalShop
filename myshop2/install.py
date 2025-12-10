import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings_prod')
django.setup()

from django.core.management import call_command

def main():
    # Collect static files
    call_command('collectstatic', '--noinput')
    
    # Run migrations
    call_command('migrate')
    
    # Create superuser if needed
    # call_command('createsuperuser')

if __name__ == '__main__':
    main() 