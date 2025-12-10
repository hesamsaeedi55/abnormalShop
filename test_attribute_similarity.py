#!/usr/bin/env python3
"""
Test script for attribute-based similar products functionality
Run this script to test the new Django endpoint
"""

import os
import sys
import django
from django.test import RequestFactory
from django.contrib.auth.models import User

# Add the Django project to the Python path
sys.path.append('/Users/hesamoddinsaeedi/Desktop/best/backup copy 53/myshop2/myshop')

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from shop.models import Product, Tag, Category, ProductAttribute, ProductAttributeValue
from shop.views import get_similar_products_by_attributes

def test_attribute_similarity():
    """Test the attribute-based similar products functionality"""
    print("🧪 Testing Attribute-Based Similar Products Functionality")
    print("=" * 60)
    
    # Create a mock request
    factory = RequestFactory()
    
    # Test 1: Get products with attributes
    print("\n1️⃣ Finding products with attributes...")
    products_with_attributes = Product.objects.filter(
        models.Q(legacy_attribute_set__isnull=False) | 
        models.Q(attribute_values__isnull=False)
    ).distinct()[:3]
    
    if not products_with_attributes:
        print("❌ No products with attributes found in database")
        print("   Please add some products with attributes to test this functionality")
        return
    
    print(f"Found {len(products_with_attributes)} products with attributes")
    
    # Test 2: Test attribute similarity for each product
    for i, product in enumerate(products_with_attributes, 1):
        print(f"\n{i+1}️⃣ Testing Attribute Similarity for Product: {product.name}")
        print(f"   Product ID: {product.id}")
        
        # Show product's attributes
        attributes = []
        for attr in product.legacy_attribute_set.all():
            attributes.append(f"{attr.key}: {attr.value}")
        for attr_value in product.attribute_values.all():
            value = attr_value.get_display_value()
            attributes.append(f"{attr_value.attribute.key}: {value}")
        
        if attributes:
            print(f"   Product attributes: {', '.join(attributes[:3])}")
        else:
            print("   No attributes found")
            continue
        
        # Test the API endpoint
        request = factory.get(f'/product/{product.id}/similar-by-attributes/')
        response = get_similar_products_by_attributes(request, product.id)
        
        print(f"   API Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Found {data['total_found']} similar products")
            
            if data['similar_products']:
                for similar in data['similar_products'][:2]:  # Show first 2
                    print(f"     - {similar['name']}: {similar['attribute_overlap']} attribute overlap")
            else:
                print("     No similar products found")
        else:
            print(f"   Error: {response.content.decode()}")
    
    print("\n✅ Attribute similarity testing completed!")

def show_attribute_stats():
    """Show current database statistics for attributes and products"""
    print("\n📊 Attribute Database Statistics")
    print("=" * 40)
    
    total_products = Product.objects.count()
    
    # Count products with legacy attributes
    products_with_legacy_attrs = Product.objects.filter(
        legacy_attribute_set__isnull=False
    ).distinct().count()
    
    # Count products with new attributes
    products_with_new_attrs = Product.objects.filter(
        attribute_values__isnull=False
    ).distinct().count()
    
    # Count products with any attributes
    products_with_any_attrs = Product.objects.filter(
        models.Q(legacy_attribute_set__isnull=False) | 
        models.Q(attribute_values__isnull=False)
    ).distinct().count()
    
    total_legacy_attrs = ProductAttribute.objects.count()
    total_new_attrs = ProductAttributeValue.objects.count()
    
    print(f"Total Products: {total_products}")
    print(f"Products with Legacy Attributes: {products_with_legacy_attrs}")
    print(f"Products with New Attributes: {products_with_new_attrs}")
    print(f"Products with Any Attributes: {products_with_any_attrs}")
    print(f"Total Legacy Attributes: {total_legacy_attrs}")
    print(f"Total New Attributes: {total_new_attrs}")
    
    if total_products > 0:
        coverage = (products_with_any_attrs / total_products) * 100
        print(f"Attribute Coverage: {coverage:.1f}%")
    
    # Show some sample attributes
    if total_legacy_attrs > 0:
        print("\nSample Legacy Attributes:")
        for attr in ProductAttribute.objects.all()[:5]:
            print(f"  - {attr.key}: {attr.value}")
    
    if total_new_attrs > 0:
        print("\nSample New Attributes:")
        for attr_value in ProductAttributeValue.objects.all()[:5]:
            value = attr_value.get_display_value()
            print(f"  - {attr_value.attribute.key}: {value}")

if __name__ == "__main__":
    try:
        from django.db import models
        show_attribute_stats()
        test_attribute_similarity()
    except Exception as e:
        print(f"❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()
