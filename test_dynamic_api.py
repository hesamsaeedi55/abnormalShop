#!/usr/bin/env python3
"""
Test script for the dynamic attribute API endpoint
"""

import requests
import json

def test_dynamic_api():
    """Test the dynamic attribute API endpoint"""
    
    # Test with category ID 1027 (ساعت مردانه)
    category_id = 1027
    base_url = "http://127.0.0.1:8000"
    
    print(f"🧪 Testing dynamic API for category {category_id}")
    print("=" * 50)
    
    # Test the dynamic endpoint
    dynamic_url = f"{base_url}/shop/api/category/{category_id}/dynamic-attribute-values/"
    
    try:
        response = requests.get(dynamic_url)
        print(f"📡 Dynamic API Response Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Dynamic API Response:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            
            # Extract key information
            attribute_key = data.get('attribute_key', 'Unknown')
            values = data.get('values', [])
            category_name = data.get('category', {}).get('name', 'Unknown')
            
            print(f"\n📊 Summary:")
            print(f"   Category: {category_name} (ID: {category_id})")
            print(f"   Dynamic Attribute Key: {attribute_key}")
            print(f"   Number of Values: {len(values)}")
            print(f"   Values: {', '.join(values[:5])}{'...' if len(values) > 5 else ''}")
            
        else:
            print(f"❌ Error: {response.status_code}")
            print(response.text)
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")
    
    print("\n" + "=" * 50)
    
    # Test the old static endpoint for comparison
    print("🧪 Testing static API for comparison")
    static_url = f"{base_url}/shop/api/category/{category_id}/attribute/برند/values/"
    
    try:
        response = requests.get(static_url)
        print(f"📡 Static API Response Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Static API Response:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            
            # Extract key information
            attribute_key = data.get('attribute_key', 'Unknown')
            values = data.get('values', [])
            
            print(f"\n📊 Summary:")
            print(f"   Static Attribute Key: {attribute_key}")
            print(f"   Number of Values: {len(values)}")
            print(f"   Values: {', '.join(values[:5])}{'...' if len(values) > 5 else ''}")
            
        else:
            print(f"❌ Error: {response.status_code}")
            print(response.text)
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request failed: {e}")

if __name__ == "__main__":
    test_dynamic_api()
