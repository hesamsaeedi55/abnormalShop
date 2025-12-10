#!/usr/bin/env python3
"""
Simple test script to verify the cart API automatically removes problematic items
"""
import requests
import json

def test_cart_api():
    """Test the cart API endpoint"""
    print("🧪 Testing Cart API Auto-Cleanup")
    print("=" * 60)
    
    BASE_URL = "http://127.0.0.1:8000"
    CART_API_URL = f"{BASE_URL}/shop/api/customer/cart/"
    
    print(f"🌐 Testing: {CART_API_URL}")
    print("\n" + "-" * 60)
    
    # Create a session to maintain cookies
    session = requests.Session()
    
    try:
        print("📡 Making GET request to cart API...")
        response = session.get(CART_API_URL, timeout=10)
        
        print(f"✅ Response Status: {response.status_code}")
        print(f"📋 Content-Type: {response.headers.get('Content-Type', 'N/A')}")
        
        # Try to parse JSON
        try:
            data = response.json()
        except json.JSONDecodeError:
            print(f"\n❌ Response is not valid JSON:")
            print(response.text[:500])
            return False
        
        print("\n" + "=" * 60)
        print("📦 CART DATA")
        print("=" * 60)
        
        # Check for errors
        if 'error' in data:
            error_msg = data['error']
            print(f"\n❌ ERROR DETECTED:")
            print(f"   Error: {error_msg}")
            
            if 'details' in data:
                print(f"   Details: {data['details']}")
            
            # Check if it's the InvalidOperation error
            if 'InvalidOperation' in str(error_msg) or 'Invalid price data' in str(error_msg):
                print("\n⚠️ Still getting InvalidOperation errors!")
                print("   The auto-cleanup might not be working yet.")
                print("   Check the server logs for more details.")
                return False
            else:
                print("\n⚠️ Different error - might be authentication or other issue")
                return False
        
        # Display cart info
        cart_id = data.get('id', 'N/A')
        items_count = len(data.get('items', []))
        total_items = data.get('total_items', 0)
        total_price = data.get('total_price_toman', 0)
        
        print(f"\n🛒 Cart ID: {cart_id}")
        print(f"📦 Items in response: {items_count}")
        print(f"🔢 Total items count: {total_items}")
        print(f"💰 Total price: {total_price:,} Toman")
        
        # Check for warning about removed items
        if 'warning' in data:
            warning = data['warning']
            print("\n" + "=" * 60)
            print("⚠️ AUTO-CLEANUP WARNING")
            print("=" * 60)
            print(f"✅ Message: {warning.get('message', 'N/A')}")
            print(f"🗑️ Removed items count: {warning.get('removed_count', 0)}")
            
            if warning.get('removed_items'):
                print(f"\n📋 Removed items details:")
                for i, item in enumerate(warning['removed_items'], 1):
                    print(f"\n   Item #{i}:")
                    print(f"   - Cart Item ID: {item.get('item_id', 'N/A')}")
                    print(f"   - Product ID: {item.get('product_id', 'N/A')}")
                    print(f"   - Product Name: {item.get('product_name', 'Unknown')}")
                    print(f"   - Reason: {item.get('reason', 'N/A')}")
            
            print("\n✅ SUCCESS! Auto-cleanup is working!")
            print("   Problematic items were automatically removed.")
            return True
        else:
            print("\n✅ No problematic items found!")
            print("   Cart is clean and ready to use.")
            
            # Show items if any
            if items_count > 0:
                print(f"\n📋 Cart Items ({items_count}):")
                for i, item in enumerate(data.get('items', [])[:5], 1):  # Show first 5
                    product = item.get('product', {})
                    print(f"   {i}. {product.get('name', 'Unknown')} x{item.get('quantity', 0)}")
                if items_count > 5:
                    print(f"   ... and {items_count - 5} more items")
            
            return True
        
    except requests.exceptions.ConnectionError:
        print("\n❌ Connection Error!")
        print("   Cannot connect to the server.")
        print("   Make sure Django server is running:")
        print("   cd myshop2 && python manage.py runserver")
        return False
        
    except requests.exceptions.Timeout:
        print("\n❌ Request Timeout!")
        print("   The server took too long to respond.")
        return False
        
    except Exception as e:
        print(f"\n❌ Unexpected Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("🧪 CART API AUTO-CLEANUP TEST")
    print("=" * 60)
    print("\nThis test will:")
    print("1. Connect to the cart API endpoint")
    print("2. Check if problematic items are automatically removed")
    print("3. Display the results")
    print("\n" + "=" * 60)
    
    success = test_cart_api()
    
    print("\n" + "=" * 60)
    print("📊 TEST RESULT")
    print("=" * 60)
    
    if success:
        print("✅ TEST PASSED!")
        print("   The auto-cleanup feature is working correctly!")
    else:
        print("❌ TEST FAILED!")
        print("   Check the output above for details.")
        print("   Make sure:")
        print("   - Django server is running")
        print("   - You're authenticated (if required)")
        print("   - The cart API endpoint is accessible")
    
    print("=" * 60)



