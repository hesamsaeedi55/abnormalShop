#!/usr/bin/env python3
import os
import sys
import django

# Add the myshop2/myshop directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'myshop'))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from accounts.models import Customer

def check_user_login_method(email):
    """Check the login method of a user by email"""
    try:
        user = Customer.objects.get(email=email)
        print(f"✅ User found: {user.email}")
        print(f"📝 Login method: {user.login_method}")
        print(f"👤 Username: {user.username}")
        print(f"📅 Created: {user.created_at}")
        print(f"✅ Is active: {user.is_active}")
        return user
    except Customer.DoesNotExist:
        print(f"❌ No user found with email: {email}")
        return None

def list_all_users():
    """List all users in the database"""
    users = Customer.objects.all().order_by('created_at')
    print(f"\n📊 Total users in database: {users.count()}")
    print("\n" + "="*60)
    print("ALL USERS IN DATABASE:")
    print("="*60)
    
    for user in users:
        print(f"📧 {user.email} | 🔐 {user.login_method} | 📅 {user.created_at}")

if __name__ == "__main__":
    print("🔍 User Login Method Checker")
    print("="*40)
    
    # Check specific user (replace with the email you're testing)
    test_email = input("Enter the email to check (or press Enter to list all users): ").strip()
    
    if test_email:
        check_user_login_method(test_email)
    else:
        list_all_users() 