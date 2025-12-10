#!/bin/bash
cd "/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop"

python manage.py shell <<EOF
from shop.models import Category, CategoryAttribute, AttributeValue

# Get category
cat = Category.objects.get(id=1040)
print(f"Found category: {cat.name}")

# Check existing attributes
existing = CategoryAttribute.objects.filter(category=cat).count()
print(f"Current attributes: {existing}")

if existing == 0:
    print("Adding attributes...")
    
    # Brand
    brand = CategoryAttribute.objects.create(category=cat, key='brand', type='text', required=True)
    print("✅ Added: brand")
    
    # Color with values
    color = CategoryAttribute.objects.create(category=cat, key='color', type='choice', required=False)
    for c in ['قرمز', 'آبی', 'سفید', 'مشکی']:
        AttributeValue.objects.create(attribute=color, value=c)
    print("✅ Added: color (with values)")
    
    # Size with values
    size = CategoryAttribute.objects.create(category=cat, key='size', type='choice', required=False)
    for s in ['کوچک', 'متوسط', 'بزرگ']:
        AttributeValue.objects.create(attribute=size, value=s)
    print("✅ Added: size (with values)")
    
    # Material
    material = CategoryAttribute.objects.create(category=cat, key='material', type='text', required=False)
    print("✅ Added: material")
    
    final = CategoryAttribute.objects.filter(category=cat).count()
    print(f"\\nTotal attributes now: {final}")
    print("\\n✅ Done! Refresh your browser page.")
else:
    print("Attributes already exist:")
    for attr in CategoryAttribute.objects.filter(category=cat):
        print(f"  - {attr.key}")
EOF

