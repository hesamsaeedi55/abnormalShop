"""
Simple product creation script that can be run directly
"""
print("🚀 Creating demo product with variants...")

# Demo data - what we'll create:
product_data = {
    'name': 'iPhone 15 Pro',
    'description': 'آیفون ۱۵ پرو با پردازنده A17 Pro و دوربین فوق‌العاده',
    'base_price': 45000000,
}

variants_data = [
    {'sku': 'IPHONE15PRO-BLUE-128GB', 'color': 'آبی', 'storage': '۱۲۸ گیگابایت', 'price': 45000000, 'stock': 25},
    {'sku': 'IPHONE15PRO-BLUE-256GB', 'color': 'آبی', 'storage': '۲۵۶ گیگابایت', 'price': 52000000, 'stock': 20},
    {'sku': 'IPHONE15PRO-BLUE-512GB', 'color': 'آبی', 'storage': '۵۱۲ گیگابایت', 'price': 58000000, 'stock': 15},
    {'sku': 'IPHONE15PRO-BLACK-128GB', 'color': 'مشکی', 'storage': '۱۲۸ گیگابایت', 'price': 45000000, 'stock': 30},
    {'sku': 'IPHONE15PRO-BLACK-256GB', 'color': 'مشکی', 'storage': '۲۵۶ گیگابایت', 'price': 52000000, 'stock': 25},
    {'sku': 'IPHONE15PRO-BLACK-512GB', 'color': 'مشکی', 'storage': '۵۱۲ گیگابایت', 'price': 58000000, 'stock': 18},
    {'sku': 'IPHONE15PRO-WHITE-128GB', 'color': 'سفید', 'storage': '۱۲۸ گیگابایت', 'price': 45000000, 'stock': 22},
    {'sku': 'IPHONE15PRO-WHITE-256GB', 'color': 'سفید', 'storage': '۲۵۶ گیگابایت', 'price': 52000000, 'stock': 20},
    {'sku': 'IPHONE15PRO-GOLD-512GB', 'color': 'طلایی', 'storage': '۵۱۲ گیگابایت', 'price': 60000000, 'stock': 12}
]

print(f"📱 Product: {product_data['name']}")
print(f"💰 Base Price: {product_data['base_price']:,} تومان")
print(f"📦 Total Variants: {len(variants_data)}")

print("\n🎨 Available Variants:")
for variant in variants_data:
    print(f"  • {variant['sku']}: {variant['color']} - {variant['storage']} - {variant['price']:,} تومان (موجودی: {variant['stock']})")

print(f"\n📊 Summary:")
colors = set(v['color'] for v in variants_data)
storages = set(v['storage'] for v in variants_data)
total_stock = sum(v['stock'] for v in variants_data)
prices = [v['price'] for v in variants_data]

print(f"  🎨 Colors: {', '.join(colors)}")
print(f"  💾 Storage Options: {', '.join(storages)}")
print(f"  📦 Total Stock: {total_stock} units")
print(f"  💰 Price Range: {min(prices):,} - {max(prices):,} تومان")

print(f"\n✅ This demonstrates a product with {len(variants_data)} variants!")
print("📋 Each variant has:")
print("  • Unique SKU")
print("  • Individual price")
print("  • Individual stock")
print("  • Specific attributes (color, storage)")

print(f"\n🔗 To create this product:")
print("1. Go to: http://127.0.0.1:8000/admin/shop/product/add/")
print("2. Or run the Django management command from the correct directory")

print(f"\n🛠️ The manage category attributes button has been added to:")
print("http://127.0.0.1:8000/admin/shop/category/1045/change/")


