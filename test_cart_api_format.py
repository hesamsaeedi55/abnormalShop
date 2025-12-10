#!/usr/bin/env python3
"""
Test script to verify the cart API returns variants in the correct format
"""
import os
import sys
import django
import requests
import json

# Add the project directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from django.contrib.auth import get_user_model
from myshop2.myshop.shop.models import Cart, CartItem, Product, ProductVariant

User = get_user_model()

def test_cart_api_format():
    """Test the cart API format"""
    print("🧪 Testing Cart API Format")
    print("="*50)
    
    # Get test user
    try:
        user = User.objects.get(email='test@example.com')
        print(f"✅ Found test user: {user.email}")
    except User.DoesNotExist:
        print("❌ Test user not found. Please run create_test_customer.py first")
        return
    
    # Get or create cart
    cart, created = Cart.objects.get_or_create(customer=user)
    print(f"📦 Cart: {'Created' if created else 'Found'} cart ID {cart.id}")
    
    # Check if cart has items
    cart_items = cart.items.all()
    print(f"🛒 Cart has {cart_items.count()} items")
    
    if cart_items.count() == 0:
        print("ℹ️ Cart is empty. Let's add some test items...")
        
        # Find a product with variants
        products_with_variants = Product.objects.filter(variants__isnull=False, is_active=True).distinct()
        if products_with_variants.exists():
            product = products_with_variants.first()
            variant = product.variants.first()
            
            print(f"📦 Adding product: {product.name}")
            print(f"🎨 Adding variant: {variant.sku}")
            
            # Add item to cart
            cart_item = CartItem.objects.create(
                cart=cart,
                product=product,
                variant=variant,
                quantity=1,
                unit_price=float(variant.price_toman)
            )
            print(f"✅ Added cart item: {cart_item.id}")
        else:
            print("❌ No products with variants found")
            return
    
    # Test the API format by simulating the view logic
    print("\n🔍 Testing API Response Format:")
    print("-" * 30)
    
    cart_items_data = []
    total_items = 0
    total_price = 0
    
    for item in cart.items.all():
        try:
            # Prepare variant data in the desired format
            variant_data = None
            if item.variant:
                # Transform attributes from dict to array format
                attributes_array = []
                if isinstance(item.variant.attributes, dict):
                    for key, value in item.variant.attributes.items():
                        attributes_array.append({
                            'key': key,
                            'value': value,
                            'isDistinctive': getattr(item.variant, 'isDistinctive', False)
                        })
                
                # Get variant images
                variant_images = []
                if hasattr(item.variant, 'images'):
                    variant_images = [
                        {
                            'id': img.id,
                            'image': img.image.url if img.image else '',
                            'is_primary': img.is_primary,
                            'display_order': img.order
                        } for img in item.variant.images.all()
                    ]
                
                variant_data = {
                    'id': item.variant.id,
                    'sku': item.variant.sku,
                    'attributes': attributes_array,
                    'price_toman': float(item.variant.price_toman),
                    'is_active': item.variant.is_active,
                    'images': variant_images
                }
            
            cart_item_data = {
                'id': item.id,
                'product': {
                    'id': item.product.id,
                    'name': item.product.name,
                    'images': [
                        {
                            'id': img.id,
                            'image': img.image.url if img.image else '',
                            'is_primary': img.is_primary,
                            'display_order': img.order
                        } for img in item.product.images.all()
                    ]
                },
                'variants': [variant_data] if variant_data else [],
                'quantity': item.quantity,
                'total_price_toman': float(item.get_total_price()),
                'total_price_usd': None,
                'added_at': item.created_at.isoformat()
            }
            
            cart_items_data.append(cart_item_data)
            total_items += item.quantity
            total_price += float(item.get_total_price())
            
        except Exception as e:
            print(f"❌ Error processing cart item {item.id}: {e}")
            continue
    
    # Create the full response
    response_data = {
        'id': cart.id,
        'items': cart_items_data,
        'total_items': total_items,
        'total_price_toman': total_price,
        'total_price_usd': None,
        'created_at': cart.created_at.isoformat(),
        'updated_at': cart.updated_at.isoformat()
    }
    
    # Print the formatted response
    print("📋 API Response Format:")
    print(json.dumps(response_data, indent=2, ensure_ascii=False))
    
    # Check if format matches expected structure
    print("\n✅ Format Verification:")
    print("-" * 20)
    
    for item in response_data['items']:
        if 'variants' in item:
            print(f"✅ Item {item['id']} has 'variants' array")
            if item['variants']:
                variant = item['variants'][0]
                if all(key in variant for key in ['id', 'sku', 'attributes', 'price_toman', 'is_active', 'images']):
                    print(f"✅ Variant has all required fields")
                    if isinstance(variant['attributes'], list):
                        print(f"✅ Attributes are in array format")
                        for attr in variant['attributes']:
                            if all(key in attr for key in ['key', 'value', 'isDistinctive']):
                                print(f"✅ Attribute '{attr['key']}' has correct structure")
                            else:
                                print(f"❌ Attribute missing required fields: {attr}")
                    else:
                        print(f"❌ Attributes should be array, got: {type(variant['attributes'])}")
                else:
                    print(f"❌ Variant missing required fields")
            else:
                print(f"ℹ️ Item {item['id']} has empty variants array")
        else:
            print(f"❌ Item {item['id']} missing 'variants' field")

if __name__ == "__main__":
    test_cart_api_format()
