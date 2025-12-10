#!/usr/bin/env python3
"""
Diagnostic script to check why product ID 243 has invalid price
"""
import os
import sys
import django

# Add the project directory to the Python path
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'myshop2'))

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from myshop.shop.models import Product
from decimal import Decimal, InvalidOperation
from django.db import connection

def check_product_price(product_id=243):
    """Check product price fields for issues"""
    print(f"🔍 Checking Product ID {product_id}")
    print("=" * 60)
    
    try:
        product = Product.objects.get(id=product_id)
        print(f"✅ Product found: {product.name}")
        print(f"   SKU: {product.sku}")
        print(f"   Active: {product.is_active}")
    except Product.DoesNotExist:
        print(f"❌ Product ID {product_id} not found")
        return
    except Exception as e:
        print(f"❌ Error loading product: {e}")
        return
    
    print("\n" + "-" * 60)
    print("📊 Checking Price Fields")
    print("-" * 60)
    
    # Check price_toman
    print("\n1. price_toman:")
    try:
        price_toman = product.price_toman
        print(f"   Value: {price_toman}")
        print(f"   Type: {type(price_toman)}")
        if price_toman is not None:
            if isinstance(price_toman, Decimal):
                print(f"   Is NaN: {price_toman.is_nan()}")
                print(f"   Is Infinite: {price_toman.is_infinite()}")
                try:
                    float_val = float(price_toman)
                    print(f"   As float: {float_val}")
                except Exception as e:
                    print(f"   ❌ Error converting to float: {e}")
            else:
                print(f"   ⚠️ Not a Decimal type: {type(price_toman)}")
        else:
            print("   ⚠️ Value is None")
    except InvalidOperation as e:
        print(f"   ❌ InvalidOperation: {e}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # Check reduced_price_toman
    print("\n2. reduced_price_toman:")
    try:
        reduced_price = product.reduced_price_toman
        print(f"   Value: {reduced_price}")
        if reduced_price is not None:
            if isinstance(reduced_price, Decimal):
                print(f"   Is NaN: {reduced_price.is_nan()}")
                print(f"   Is Infinite: {reduced_price.is_infinite()}")
                try:
                    float_val = float(reduced_price)
                    print(f"   As float: {float_val}")
                except Exception as e:
                    print(f"   ❌ Error converting to float: {e}")
            else:
                print(f"   ⚠️ Not a Decimal type: {type(reduced_price)}")
        else:
            print("   Value is None (OK)")
    except InvalidOperation as e:
        print(f"   ❌ InvalidOperation: {e}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # Check discount_percentage
    print("\n3. discount_percentage:")
    try:
        discount = product.discount_percentage
        print(f"   Value: {discount}")
        if discount is not None:
            if isinstance(discount, Decimal):
                print(f"   Is NaN: {discount.is_nan()}")
                print(f"   Is Infinite: {discount.is_infinite()}")
                try:
                    float_val = float(discount)
                    print(f"   As float: {float_val}")
                except Exception as e:
                    print(f"   ❌ Error converting to float: {e}")
            else:
                print(f"   ⚠️ Not a Decimal type: {type(discount)}")
        else:
            print("   Value is None (OK)")
    except InvalidOperation as e:
        print(f"   ❌ InvalidOperation: {e}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # Check price_usd
    print("\n4. price_usd:")
    try:
        price_usd = product.price_usd
        print(f"   Value: {price_usd}")
        if price_usd is not None:
            if isinstance(price_usd, Decimal):
                print(f"   Is NaN: {price_usd.is_nan()}")
                print(f"   Is Infinite: {price_usd.is_infinite()}")
                try:
                    float_val = float(price_usd)
                    print(f"   As float: {float_val}")
                except Exception as e:
                    print(f"   ❌ Error converting to float: {e}")
            else:
                print(f"   ⚠️ Not a Decimal type: {type(price_usd)}")
        else:
            print("   Value is None (OK)")
    except InvalidOperation as e:
        print(f"   ❌ InvalidOperation: {e}")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # Check raw database values
    print("\n" + "-" * 60)
    print("🗄️ Raw Database Values (SQL)")
    print("-" * 60)
    
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    price_toman,
                    reduced_price_toman,
                    discount_percentage,
                    price_usd
                FROM shop_product 
                WHERE id = %s
            """, [product_id])
            
            row = cursor.fetchone()
            if row:
                print(f"\nRaw values from database:")
                print(f"  price_toman: {repr(row[0])} (type: {type(row[0])})")
                print(f"  reduced_price_toman: {repr(row[1])} (type: {type(row[1])})")
                print(f"  discount_percentage: {repr(row[2])} (type: {type(row[2])})")
                print(f"  price_usd: {repr(row[3])} (type: {type(row[3])})")
                
                # Check for special values
                for i, field_name in enumerate(['price_toman', 'reduced_price_toman', 'discount_percentage', 'price_usd']):
                    val = row[i]
                    if val is not None:
                        val_str = str(val).upper()
                        if 'NAN' in val_str or 'INF' in val_str or 'NULL' in val_str:
                            print(f"\n  ⚠️ {field_name} has suspicious value: {repr(val)}")
            else:
                print("  No data found")
    except Exception as e:
        print(f"  ❌ Error querying database: {e}")
    
    # Check CartItems that reference this product
    print("\n" + "-" * 60)
    print("🛒 Cart Items Using This Product")
    print("-" * 60)
    
    try:
        from myshop.shop.models import CartItem
        cart_items = CartItem.objects.filter(product=product)
        print(f"Found {cart_items.count()} cart item(s) with this product")
        
        if cart_items.exists():
            for item in cart_items[:5]:  # Show first 5
                print(f"\n  Cart Item ID: {item.id}")
                print(f"    Cart ID: {item.cart.id}")
                print(f"    Quantity: {item.quantity}")
                try:
                    unit_price = item.unit_price
                    print(f"    Unit Price: {unit_price} (type: {type(unit_price)})")
                    if unit_price is not None and isinstance(unit_price, Decimal):
                        print(f"      Is NaN: {unit_price.is_nan()}")
                        print(f"      Is Infinite: {unit_price.is_infinite()}")
                except Exception as e:
                    print(f"    ❌ Error accessing unit_price: {e}")
    except Exception as e:
        print(f"  ❌ Error: {e}")
    
    print("\n" + "=" * 60)
    print("📋 Summary")
    print("=" * 60)
    print("Check the output above for:")
    print("  - NaN or Infinity values")
    print("  - InvalidOperation errors")
    print("  - Suspicious database values")
    print("  - Cart items with invalid unit_price")

if __name__ == "__main__":
    check_product_price(243)



