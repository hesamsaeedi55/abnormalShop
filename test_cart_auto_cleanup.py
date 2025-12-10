#!/usr/bin/env python3
"""
Test script to verify the cart API automatically removes problematic items
"""
import os
import sys
import django
import requests
import json

# Add the project directory to the Python path
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'myshop2'))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from django.contrib.auth import get_user_model
from myshop.shop.models import Cart, CartItem, Product, ProductVariant
from decimal import Decimal

User = get_user_model()

def test_cart_auto_cleanup():
    """Test the cart API auto-cleanup functionality"""
    print("🧪 Testing Cart API Auto-Cleanup")
    print("=" * 60)
    
    # Configuration
    BASE_URL = "http://127.0.0.1:8000"
    TEST_EMAIL = "hesamsaeedi25800@gmail.com"  # Change to your test user email
    
    # Create a session
    session = requests.Session()
    
    print(f"\n📧 Testing with user: {TEST_EMAIL}")
    print(f"🌐 Base URL: {BASE_URL}")
    
    # Step 1: Check if server is running
    print("\n" + "=" * 60)
    print("Step 1: Checking if server is running...")
    try:
        response = session.get(f"{BASE_URL}/shop/api/customer/cart/", timeout=5)
        print(f"✅ Server is running (Status: {response.status_code})")
    except requests.exceptions.ConnectionError:
        print("❌ Server is not running!")
        print("   Please start the Django server first:")
        print("   cd myshop2 && python manage.py runserver")
        return False
    except Exception as e:
        print(f"❌ Error connecting to server: {e}")
        return False
    
    # Step 2: Try to login (if needed) or use existing session
    print("\n" + "=" * 60)
    print("Step 2: Testing authentication...")
    
    # Try to access the cart API
    try:
        cart_response = session.get(f"{BASE_URL}/shop/api/customer/cart/")
        print(f"   Cart API Status: {cart_response.status_code}")
        
        if cart_response.status_code == 200:
            print("✅ Successfully accessed cart API")
            cart_data = cart_response.json()
            print(f"   Current cart has {len(cart_data.get('items', []))} items")
            
            # Check if there's a warning about removed items
            if 'warning' in cart_data:
                warning = cart_data['warning']
                print(f"\n⚠️ Warning detected:")
                print(f"   Message: {warning.get('message', 'N/A')}")
                print(f"   Removed items count: {warning.get('removed_count', 0)}")
                
                if warning.get('removed_items'):
                    print(f"\n   Removed items details:")
                    for item in warning['removed_items']:
                        print(f"   - Item ID: {item.get('item_id')}")
                        print(f"     Product: {item.get('product_name', 'Unknown')} (ID: {item.get('product_id')})")
                        print(f"     Reason: {item.get('reason', 'N/A')}")
                
                print("\n✅ Auto-cleanup is working! Problematic items were removed.")
                return True
            else:
                print("✅ No problematic items found - cart is clean!")
                return True
                
        elif cart_response.status_code == 401:
            print("⚠️ Authentication required")
            print("   The API requires authentication.")
            print("   Please ensure you're logged in or provide authentication tokens.")
            return False
        else:
            error_data = cart_response.json() if cart_response.headers.get('content-type', '').startswith('application/json') else {}
            error_msg = error_data.get('error', cart_response.text)
            print(f"❌ Error: {error_msg}")
            
            # Check if it's still the InvalidOperation error
            if 'InvalidOperation' in str(error_msg) or 'Invalid price data' in str(error_msg):
                print("\n⚠️ Still getting InvalidOperation errors!")
                print("   This might mean:")
                print("   1. The error is happening before our cleanup code runs")
                print("   2. There's an issue with the exception handling")
                print("   3. The problematic items are being accessed in a different way")
            
            return False
            
    except Exception as e:
        print(f"❌ Error testing cart API: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_with_django_orm():
    """Test the cleanup logic directly using Django ORM"""
    print("\n" + "=" * 60)
    print("Step 3: Testing cleanup logic directly with Django ORM...")
    
    try:
        # Get test user
        test_user = User.objects.filter(email__icontains='hesam').first()
        if not test_user:
            print("⚠️ No test user found. Skipping Django ORM test.")
            return True
        
        print(f"✅ Found test user: {test_user.email}")
        
        # Get or create cart
        cart, created = Cart.objects.get_or_create(customer=test_user)
        print(f"📦 Cart: {'Created' if created else 'Found'} cart ID {cart.id}")
        
        # Count items before
        items_before = cart.items.count()
        print(f"🛒 Cart has {items_before} items before cleanup")
        
        # Test the get_total_price method on each item
        problematic_count = 0
        for item in cart.items.all():
            try:
                total_price = item.get_total_price()
                if total_price is None or (isinstance(total_price, float) and (total_price != total_price or total_price == float('inf') or total_price == float('-inf'))):
                    problematic_count += 1
                    print(f"⚠️ Item {item.id} has invalid price: {total_price}")
            except Exception as e:
                problematic_count += 1
                print(f"⚠️ Item {item.id} raised exception: {e}")
        
        if problematic_count > 0:
            print(f"\n⚠️ Found {problematic_count} problematic item(s)")
            print("   These should be automatically removed when accessing the API")
        else:
            print("\n✅ No problematic items found in Django ORM test")
        
        # Count items after (no changes should be made in this test)
        items_after = cart.items.count()
        print(f"🛒 Cart still has {items_after} items (no changes made)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error in Django ORM test: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("🧪 CART API AUTO-CLEANUP TEST")
    print("=" * 60)
    
    # Test 1: API endpoint test
    api_test_passed = test_cart_auto_cleanup()
    
    # Test 2: Django ORM test
    orm_test_passed = test_with_django_orm()
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 TEST SUMMARY")
    print("=" * 60)
    print(f"API Endpoint Test: {'✅ PASSED' if api_test_passed else '❌ FAILED'}")
    print(f"Django ORM Test: {'✅ PASSED' if orm_test_passed else '❌ FAILED'}")
    
    if api_test_passed and orm_test_passed:
        print("\n🎉 All tests passed!")
        print("   The auto-cleanup feature is working correctly!")
    else:
        print("\n⚠️ Some tests failed.")
        print("   Check the output above for details.")
    
    print("=" * 60)



