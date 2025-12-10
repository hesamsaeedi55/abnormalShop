#!/usr/bin/env python3
import os
import sys
import django
import requests
import json

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from accounts.models import Customer

def test_google_auth_endpoint(email):
    """Test the Google auth endpoint with a mock token"""
    print(f"🧪 Testing Google auth endpoint for user: {email}")
    print("="*50)
    
    # First, check if user exists and their login method
    try:
        user = Customer.objects.get(email=email)
        print(f"✅ User found in database:")
        print(f"   📧 Email: {user.email}")
        print(f"   🔐 Login method: {user.login_method}")
        print(f"   👤 Username: {user.username}")
    except Customer.DoesNotExist:
        print(f"❌ User {email} not found in database")
        return
    
    # Test the endpoint (this will fail because we don't have a real Google token)
    # but it will show us the debug output
    url = "http://127.0.0.1:8000/auth/google"
    payload = {"id_token": "fake_token_for_testing"}
    
    print(f"\n🌐 Testing endpoint: {url}")
    print(f"📤 Sending payload: {payload}")
    
    try:
        response = requests.post(url, json=payload, timeout=10)
        print(f"📥 Response status: {response.status_code}")
        print(f"📥 Response body: {response.text}")
    except requests.exceptions.ConnectionError:
        print("❌ Connection error - Make sure your Django server is running on port 8000")
    except Exception as e:
        print(f"❌ Error: {e}")

def check_server_logs():
    """Instructions for checking server logs"""
    print("\n📋 TO CHECK SERVER LOGS:")
    print("="*30)
    print("1. Start your Django server:")
    print("   cd myshop2")
    print("   python manage.py runserver 0.0.0.0:8000")
    print("\n2. Try logging in with Google from your iOS app")
    print("\n3. Look for this debug line in the server console:")
    print("   DEBUG: Found user user@example.com with login_method email")
    print("\n4. If you see this line, the backend should return a 400 error")
    print("   If you don't see this line, the user doesn't exist in the database")

if __name__ == "__main__":
    print("🧪 Google Auth Endpoint Tester")
    print("="*40)
    
    # Get the email to test
    test_email = input("Enter the email to test: ").strip()
    
    if test_email:
        test_google_auth_endpoint(test_email)
        check_server_logs()
    else:
        print("❌ Please provide an email address") 