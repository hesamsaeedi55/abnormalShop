#!/usr/bin/env python3
"""
Cart Debug Test Script
This script helps debug cart session issues
"""

import requests
import json

# Configuration
BASE_URL = "http://127.0.0.1:8000"
USER_EMAIL = "hesamsaeedi25800@gmail.com"

def test_cart_debug():
    """Test cart functionality step by step"""
    
    print("🔍 Cart Debug Test Starting...")
    print(f"👤 Testing for user: {USER_EMAIL}")
    print(f"🌐 Base URL: {BASE_URL}")
    
    # Create a session to maintain cookies
    session = requests.Session()
    
    # Step 1: Try to login (if needed)
    print("\n📝 Step 1: Testing login...")
    try:
        login_response = session.post(f"{BASE_URL}/accounts/login/", data={
            'email': USER_EMAIL,
            'password': 'testpass123'  # You may need to adjust this
        })
        print(f"Login status: {login_response.status_code}")
        if login_response.status_code == 200:
            print("✅ Login successful")
        else:
            print("⚠️ Login failed, continuing with session...")
    except Exception as e:
        print(f"❌ Login error: {e}")
    
    # Step 2: Check session data
    print("\n📊 Step 2: Checking session data...")
    try:
        session_response = session.get(f"{BASE_URL}/shop/api/debug/session/")
        print(f"Session API status: {session_response.status_code}")
        if session_response.status_code == 200:
            session_data = session_response.json()
            print("📦 Session data:")
            print(json.dumps(session_data, indent=2))
        else:
            print(f"❌ Session API failed: {session_response.text}")
    except Exception as e:
        print(f"❌ Session API error: {e}")
    
    # Step 3: Check current cart
    print("\n🛒 Step 3: Checking current cart...")
    try:
        cart_response = session.get(f"{BASE_URL}/shop/api/customer/cart/")
        print(f"Cart API status: {cart_response.status_code}")
        if cart_response.status_code == 200:
            cart_data = cart_response.json()
            print("🛍️ Current cart:")
            print(json.dumps(cart_data, indent=2))
        else:
            print(f"❌ Cart API failed: {cart_response.text}")
    except Exception as e:
        print(f"❌ Cart API error: {e}")
    
    # Step 4: Add item to cart
    print("\n➕ Step 4: Adding item to cart...")
    try:
        add_response = session.post(f"{BASE_URL}/shop/api/debug/add-to-cart/", 
                                  json={'product_id': 1, 'quantity': 2})
        print(f"Add to cart status: {add_response.status_code}")
        if add_response.status_code == 200:
            add_data = add_response.json()
            print("✅ Add to cart response:")
            print(json.dumps(add_data, indent=2))
        else:
            print(f"❌ Add to cart failed: {add_response.text}")
    except Exception as e:
        print(f"❌ Add to cart error: {e}")
    
    # Step 5: Check cart again
    print("\n🛒 Step 5: Checking cart after adding item...")
    try:
        cart_response = session.get(f"{BASE_URL}/shop/api/customer/cart/")
        print(f"Cart API status: {cart_response.status_code}")
        if cart_response.status_code == 200:
            cart_data = cart_response.json()
            print("🛍️ Updated cart:")
            print(json.dumps(cart_data, indent=2))
        else:
            print(f"❌ Cart API failed: {cart_response.text}")
    except Exception as e:
        print(f"❌ Cart API error: {e}")
    
    # Step 6: Check session again
    print("\n📊 Step 6: Checking session after adding item...")
    try:
        session_response = session.get(f"{BASE_URL}/shop/api/debug/session/")
        print(f"Session API status: {session_response.status_code}")
        if session_response.status_code == 200:
            session_data = session_response.json()
            print("📦 Updated session data:")
            print(json.dumps(session_data, indent=2))
        else:
            print(f"❌ Session API failed: {session_response.text}")
    except Exception as e:
        print(f"❌ Session API error: {e}")
    
    print("\n🏁 Cart Debug Test Complete!")

if __name__ == "__main__":
    test_cart_debug()
