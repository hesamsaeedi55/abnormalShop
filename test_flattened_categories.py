#!/usr/bin/env python3
"""
Test script to verify the new flattened categories API functionality
"""

import requests
import json

BASE_URL = "http://127.0.0.1:8000/shop"

def test_flattened_categories_api():
    """Test the new flattened categories API"""
    print("🧪 Testing Flattened Categories API...")
    
    # Test the new flattened API for category 1031 (اکسسوری مردانه)
    url = f"{BASE_URL}/api/categories/parent/1031/flattened-by-gender/?gender_name=men"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Success! Found {data['total_count']} categories")
        print(f"📊 Statistics: {data['statistics']}")
        print(f"📝 Message: {data['message']}")
        
        print("\n📋 Categories:")
        for category in data['categories']:
            category_type = category.get('category_type', 'unknown')
            neutral_parent = category.get('neutral_parent')
            
            if neutral_parent:
                print(f"  - {category['name']} ({category_type})")
                print(f"    └─ From neutral category: {neutral_parent['name']}")
            else:
                print(f"  - {category['name']} ({category_type})")
                
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)

def test_comparison_with_old_api():
    """Compare with the old API to show the difference"""
    print("\n🧪 Comparing with Old API...")
    
    # Old API (without neutral categories)
    old_url = f"{BASE_URL}/api/categories/parent/1031/children/by-gender/?gender_name=men"
    old_response = requests.get(old_url)
    
    if old_response.status_code == 200:
        old_data = old_response.json()
        print(f"📊 Old API: Found {old_data['total_count']} categories")
        for category in old_data['categories']:
            print(f"  - {category['name']}")
    
    # New flattened API
    new_url = f"{BASE_URL}/api/categories/parent/1031/flattened-by-gender/?gender_name=men"
    new_response = requests.get(new_url)
    
    if new_response.status_code == 200:
        new_data = new_response.json()
        print(f"📊 New Flattened API: Found {new_data['total_count']} categories")
        for category in new_data['categories']:
            category_type = category.get('category_type', 'unknown')
            print(f"  - {category['name']} ({category_type})")

def test_different_genders():
    """Test with different gender parameters"""
    print("\n🧪 Testing Different Genders...")
    
    genders = ['men', 'women']
    
    for gender in genders:
        print(f"\n🔍 Testing gender: {gender}")
        url = f"{BASE_URL}/api/categories/parent/1031/flattened-by-gender/?gender_name={gender}"
        response = requests.get(url)
        
        if response.status_code == 200:
            data = response.json()
            print(f"  ✅ Found {data['total_count']} categories")
            print(f"  📊 Direct: {data['statistics']['direct_children_count']}, Nested: {data['statistics']['nested_categories_count']}")
        else:
            print(f"  ❌ Error: {response.status_code}")

if __name__ == "__main__":
    print("🚀 Testing Flattened Categories API Implementation")
    print("=" * 60)
    
    try:
        test_flattened_categories_api()
        test_comparison_with_old_api()
        test_different_genders()
        
        print("\n✅ All tests completed!")
        print("\n🎯 Expected Results:")
        print("- دستبند مردانه (direct_child)")
        print("- کیف مردانه (direct_child)")
        print("- ساعت مردانه (nested_gender_specific) ← This should now appear!")
        
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Make sure your Django server is running on http://127.0.0.1:8000")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

