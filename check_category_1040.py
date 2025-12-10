#!/usr/bin/env python
"""
Quick script to check if category 1040 has attributes
"""
import os
import sys
import django

# Add the project directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'myshop2', 'myshop'))

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from shop.models import Category, CategoryAttribute

# Find category 1040
try:
    category = Category.objects.get(id=1040)
    print(f"✅ Found category: {category.name} (ID: {category.id})")
    
    # Get attributes
    attributes = CategoryAttribute.objects.filter(category=category)
    print(f"📊 Total attributes: {attributes.count()}")
    
    if attributes.exists():
        print("\n✅ Attributes found:")
        for attr in attributes:
            values = attr.values.all()
            print(f"  - {attr.key} (type: {attr.type}, required: {attr.required})")
            if values.exists():
                print(f"    Values: {[v.value for v in values]}")
    else:
        print("\n❌ No attributes found for this category!")
        print("\nTo add attributes, go to Django admin:")
        print(f"http://127.0.0.1:8003/admin/shop/categoryattribute/add/")
        print(f"And create attributes with category = 'Test Category' (ID: 1040)")
        
except Category.DoesNotExist:
    print(f"❌ Category with ID 1040 does not exist!")
    print("\nAvailable categories:")
    for cat in Category.objects.all()[:20]:
        print(f"  - {cat.name} (ID: {cat.id})")

