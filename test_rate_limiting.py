#!/usr/bin/env python3
"""
Test script to verify address edit rate limiting
"""

import requests
import time
import json

# Configuration
BASE_URL = "http://127.0.0.1:8000"
ADDRESS_ID = 1  # Change this to a real address ID
TOKEN = "your_access_token_here"  # Replace with actual token

def test_rate_limiting():
    """Test the rate limiting functionality"""
    
    headers = {
        "Authorization": f"Bearer {TOKEN}",
        "Content-Type": "application/json"
    }
    
    # Test data
    test_data = {
        "label": "Test Address",
        "receiver_name": "Test User",
        "street_address": "123 Test Street",
        "city": "Test City",
        "state": "Test State",
        "country": "ایران",
        "postal_code": "12345",
        "unit": "1",
        "phone": "09123456789"
    }
    
    print("🧪 Testing Address Edit Rate Limiting")
    print("=" * 50)
    
    # Test 1: First edit (should succeed)
    print("\n1️⃣ First edit attempt...")
    response = requests.put(
        f"{BASE_URL}/accounts/customer/addresses/{ADDRESS_ID}/",
        headers=headers,
        json=test_data
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("✅ First edit successful")
    else:
        print(f"❌ First edit failed: {response.text}")
    
    # Test 2: Second edit (should succeed)
    print("\n2️⃣ Second edit attempt...")
    response = requests.put(
        f"{BASE_URL}/accounts/customer/addresses/{ADDRESS_ID}/",
        headers=headers,
        json=test_data
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("✅ Second edit successful")
    else:
        print(f"❌ Second edit failed: {response.text}")
    
    # Test 3: Third edit (should be rate limited)
    print("\n3️⃣ Third edit attempt (should be rate limited)...")
    response = requests.put(
        f"{BASE_URL}/accounts/customer/addresses/{ADDRESS_ID}/",
        headers=headers,
        json=test_data
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 429:
        print("✅ Rate limiting working correctly!")
        try:
            error_data = response.json()
            print(f"Error message: {error_data.get('detail', 'No detail')}")
            print(f"Retry after: {error_data.get('retry_after', 'Unknown')} seconds")
        except:
            print(f"Response: {response.text}")
    else:
        print(f"❌ Rate limiting not working: {response.text}")
    
    # Test 4: Wait and try again (should succeed after 1 minute)
    print("\n4️⃣ Waiting 65 seconds and trying again...")
    time.sleep(65)
    
    response = requests.put(
        f"{BASE_URL}/accounts/customer/addresses/{ADDRESS_ID}/",
        headers=headers,
        json=test_data
    )
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("✅ Edit successful after waiting")
    else:
        print(f"❌ Still rate limited: {response.text}")

if __name__ == "__main__":
    print("⚠️  Make sure to:")
    print("   1. Update ADDRESS_ID with a real address ID")
    print("   2. Update TOKEN with a valid access token")
    print("   3. Ensure your Django server is running")
    print()
    
    # Uncomment the line below to run the test
    # test_rate_limiting()
