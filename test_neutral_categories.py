#!/usr/bin/env python3
"""
Test script to verify the new neutral categories API functionality
"""

import requests
import json

BASE_URL = "http://127.0.0.1:8000/shop"

def test_parent_categories_with_neutral():
    """Test parent categories API with include_neutral=true"""
    print("🧪 Testing Parent Categories with Neutral Categories...")
    
    # Test men's categories including neutral
    url = f"{BASE_URL}/api/categories/parents/by-gender/?gender_name=men&include_neutral=true"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Success! Found {data['total_count']} categories")
        print(f"📊 Statistics: {data['statistics']}")
        
        for category in data['categories']:
            gender_info = category.get('gender', {}).get('name', 'unassigned')
            print(f"  - {category['name']} (Gender: {gender_info})")
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)

def test_child_categories_with_neutral():
    """Test child categories API with include_neutral=true"""
    print("\n🧪 Testing Child Categories with Neutral Categories...")
    
    # Test children of category 1031 (اکسسوری مردانه) including neutral
    url = f"{BASE_URL}/api/categories/parent/1031/children/by-gender/?gender_name=men&include_neutral=true"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Success! Found {data['total_count']} child categories")
        print(f"📊 Statistics: {data['statistics']}")
        
        for category in data['categories']:
            gender_info = category.get('gender', {}).get('name', 'unassigned')
            print(f"  - {category['name']} (Gender: {gender_info})")
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)

def test_without_neutral():
    """Test without include_neutral for comparison"""
    print("\n🧪 Testing WITHOUT Neutral Categories (for comparison)...")
    
    url = f"{BASE_URL}/api/categories/parent/1031/children/by-gender/?gender_name=men"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        print(f"✅ Success! Found {data['total_count']} child categories (neutral excluded)")
        print(f"📊 Statistics: {data['statistics']}")
        
        for category in data['categories']:
            gender_info = category.get('gender', {}).get('name', 'unassigned')
            print(f"  - {category['name']} (Gender: {gender_info})")
    else:
        print(f"❌ Error: {response.status_code}")
        print(response.text)

if __name__ == "__main__":
    print("🚀 Testing Neutral Categories API Implementation")
    print("=" * 50)
    
    try:
        test_parent_categories_with_neutral()
        test_child_categories_with_neutral()
        test_without_neutral()
        
        print("\n✅ All tests completed!")
        
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Make sure your Django server is running on http://127.0.0.1:8000")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

