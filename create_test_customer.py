"""
Create a test customer for shopping interface testing
Run this command: python manage.py shell
Then run: exec(open('create_test_customer.py').read())
"""

from django.contrib.auth import get_user_model
from accounts.models import Customer

User = get_user_model()

# Create test customer
test_user, created = User.objects.get_or_create(
    email='test@example.com',
    defaults={
        'first_name': 'Test',
        'last_name': 'User',
        'phone_number': '+1234567890',
        'is_active': True,
    }
)

if created:
    test_user.set_password('testpass123')
    test_user.save()
    print(f"✅ Created test user: {test_user.email}")
else:
    print(f"ℹ️ Test user already exists: {test_user.email}")

print(f"📧 Email: test@example.com")
print(f"🔑 Password: testpass123")
print(f"🔗 Login URL: http://127.0.0.1:8000/accounts/shopping/")
