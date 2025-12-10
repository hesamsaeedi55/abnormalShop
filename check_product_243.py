#!/usr/bin/env python3
"""
Simple script to check product 243 price - run this in Django shell:
python manage.py shell < check_product_243.py
"""
from shop.models import Product, CartItem
from decimal import Decimal, InvalidOperation
from django.db import connection

product_id = 243

print(f"🔍 Checking Product ID {product_id}")
print("=" * 60)

try:
    product = Product.objects.get(id=product_id)
    print(f"✅ Product found: {product.name}")
    print(f"   SKU: {product.sku}")
except Product.DoesNotExist:
    print(f"❌ Product ID {product_id} not found")
    exit(1)

# Check price fields
print("\n📊 Price Fields:")
print("-" * 60)

fields_to_check = ['price_toman', 'reduced_price_toman', 'discount_percentage', 'price_usd']

for field_name in fields_to_check:
    print(f"\n{field_name}:")
    try:
        value = getattr(product, field_name)
        print(f"  Value: {value}")
        print(f"  Type: {type(value)}")
        if value is not None and isinstance(value, Decimal):
            print(f"  Is NaN: {value.is_nan()}")
            print(f"  Is Infinite: {value.is_infinite()}")
            try:
                float_val = float(value)
                print(f"  As float: {float_val}")
            except Exception as e:
                print(f"  ❌ Error converting to float: {e}")
    except InvalidOperation as e:
        print(f"  ❌ InvalidOperation: {e}")
    except Exception as e:
        print(f"  ❌ Error: {e}")

# Check raw database
print("\n🗄️ Raw Database Values:")
print("-" * 60)
try:
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT price_toman, reduced_price_toman, discount_percentage, price_usd
            FROM shop_product WHERE id = %s
        """, [product_id])
        row = cursor.fetchone()
        if row:
            print(f"price_toman: {repr(row[0])}")
            print(f"reduced_price_toman: {repr(row[1])}")
            print(f"discount_percentage: {repr(row[2])}")
            print(f"price_usd: {repr(row[3])}")
except Exception as e:
    print(f"Error: {e}")

# Check cart items
print("\n🛒 Cart Items:")
print("-" * 60)
cart_items = CartItem.objects.filter(product=product)
print(f"Found {cart_items.count()} cart item(s)")

for item in cart_items[:3]:
    print(f"\n  CartItem ID: {item.id}")
    try:
        unit_price = item.unit_price
        print(f"    unit_price: {unit_price} (type: {type(unit_price)})")
        if isinstance(unit_price, Decimal):
            print(f"      Is NaN: {unit_price.is_nan()}")
            print(f"      Is Infinite: {unit_price.is_infinite()}")
    except Exception as e:
        print(f"    ❌ Error: {e}")



