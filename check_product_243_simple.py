# Quick check script - copy and paste into Django shell
# python myshop/manage.py shell

from shop.models import Product, CartItem, ProductVariant
from decimal import Decimal, InvalidOperation
from django.db import connection

product_id = 243
product = Product.objects.get(id=product_id)

print(f"Product: {product.name}")
print(f"\nRaw DB values:")
with connection.cursor() as cursor:
    cursor.execute("SELECT price_toman, reduced_price_toman, discount_percentage FROM shop_product WHERE id = %s", [product_id])
    row = cursor.fetchone()
    print(f"  price_toman: {repr(row[0])}")
    print(f"  reduced_price_toman: {repr(row[1])}")
    print(f"  discount_percentage: {repr(row[2])}")

print(f"\nORM access:")
try:
    print(f"  price_toman: {product.price_toman}")
except Exception as e:
    print(f"  ❌ Error: {e}")

# Check cart items
cart_items = CartItem.objects.filter(product=product)
print(f"\nCart items: {cart_items.count()}")
for item in cart_items:
    try:
        print(f"  Item {item.id}: unit_price = {item.unit_price}")
    except Exception as e:
        print(f"  Item {item.id}: ❌ ERROR - {e}")
