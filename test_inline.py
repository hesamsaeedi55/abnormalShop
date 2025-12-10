#!/usr/bin/env python3
"""
Test script to check if the ProductVariant inline is working
"""
import os
import sys
import django

# Add the Django project path
sys.path.append('/Users/hesamoddinsaeedi/Desktop/best/backup copy 53/myshop2/myshop')

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from shop.models import Product, ProductVariant
from shop.admin import ProductVariantInline
from django.contrib import admin
from django.test import RequestFactory
from django.contrib.auth import get_user_model

def test_inline():
    print('=== TESTING PRODUCTVARIANT INLINE ===')
    
    # Get the product and variants
    product = Product.objects.get(id=267)
    variants = ProductVariant.objects.filter(product=product)
    
    print(f'Product: {product.name}')
    print(f'Variants: {variants.count()}')
    
    for variant in variants:
        print(f'  - {variant.sku}: {variant.attributes}')
    
    # Create a proper request with user
    factory = RequestFactory()
    request = factory.get('/admin/shop/product/267/change/')
    
    User = get_user_model()
    user = User.objects.first()
    if not user:
        print('No users found!')
        return
    
    request.user = user
    request.user.is_staff = True
    request.user.is_superuser = True
    
    print(f'User: {request.user.username}')
    
    # Test the inline
    try:
        inline = ProductVariantInline(Product, admin.site)
        formset = inline.get_formset(request, product)
        
        print('Formset created successfully')
        print(f'Formset type: {type(formset)}')
        
        # Check if formset has forms
        if hasattr(formset, 'forms'):
            forms = formset.forms
            print(f'Forms count: {len(forms)}')
            
            # Check each form
            for i, form in enumerate(forms):
                print(f'Form {i}:')
                print(f'  - Instance: {form.instance}')
                print(f'  - Instance ID: {form.instance.pk if form.instance else "None"}')
                if hasattr(form, 'instance') and form.instance.pk:
                    print(f'  - SKU: {form.instance.sku}')
                    print(f'  - Attributes: {form.instance.attributes}')
        
        print('✅ Inline is working correctly!')
        
    except Exception as e:
        print(f'Formset error: {e}')
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    test_inline()

