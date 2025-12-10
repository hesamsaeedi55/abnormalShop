#!/usr/bin/env python
"""
Add test attributes to category 1040
"""
import os
import sys
import django

# Set up Django
project_path = os.path.join(os.path.dirname(__file__), 'myshop2', 'myshop')
sys.path.insert(0, project_path)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from shop.models import Category, CategoryAttribute, AttributeValue

print("=" * 60)
print("Checking Category 1040")
print("=" * 60)

try:
    category = Category.objects.get(id=1040)
    print(f"✅ Found category: '{category.name}' (ID: {category.id})")
    
    # Check existing attributes
    existing_attrs = CategoryAttribute.objects.filter(category=category)
    print(f"\n📊 Existing attributes: {existing_attrs.count()}")
    
    if existing_attrs.exists():
        print("\nCurrent attributes:")
        for attr in existing_attrs:
            values = [v.value for v in attr.values.all()]
            print(f"  - {attr.key} (type: {attr.type}, required: {attr.required})")
            if values:
                print(f"    Values: {values}")
    else:
        print("\n❌ No attributes found! Let's add some test attributes...")
        
        # Add some test attributes
        print("\n🔧 Creating test attributes...")
        
        # Brand attribute
        brand_attr, created = CategoryAttribute.objects.get_or_create(
            category=category,
            key='brand',
            defaults={
                'type': 'text',
                'required': True
            }
        )
        if created:
            print(f"  ✅ Created: brand (text, required)")
        
        # Color attribute with values
        color_attr, created = CategoryAttribute.objects.get_or_create(
            category=category,
            key='color',
            defaults={
                'type': 'choice',
                'required': False
            }
        )
        if created:
            print(f"  ✅ Created: color (choice, optional)")
            # Add color values
            for color in ['قرمز', 'آبی', 'سفید', 'مشکی', 'سبز']:
                AttributeValue.objects.get_or_create(
                    attribute=color_attr,
                    value=color
                )
            print(f"    Added {color_attr.values.count()} color values")
        
        # Size attribute with values
        size_attr, created = CategoryAttribute.objects.get_or_create(
            category=category,
            key='size',
            defaults={
                'type': 'choice',
                'required': False
            }
        )
        if created:
            print(f"  ✅ Created: size (choice, optional)")
            # Add size values
            for size in ['کوچک', 'متوسط', 'بزرگ', 'خیلی بزرگ']:
                AttributeValue.objects.get_or_create(
                    attribute=size_attr,
                    value=size
                )
            print(f"    Added {size_attr.values.count()} size values")
        
        # Material attribute
        material_attr, created = CategoryAttribute.objects.get_or_create(
            category=category,
            key='material',
            defaults={
                'type': 'text',
                'required': False
            }
        )
        if created:
            print(f"  ✅ Created: material (text, optional)")
        
        # Weight attribute
        weight_attr, created = CategoryAttribute.objects.get_or_create(
            category=category,
            key='weight',
            defaults={
                'type': 'number',
                'required': False
            }
        )
        if created:
            print(f"  ✅ Created: weight (number, optional)")
        
        print("\n✅ Attributes created successfully!")
        
        # Verify
        final_count = CategoryAttribute.objects.filter(category=category).count()
        print(f"\n📊 Total attributes now: {final_count}")
        
        print("\n" + "=" * 60)
        print("Now refresh your browser page and select category 1040 again!")
        print("=" * 60)
        
except Category.DoesNotExist:
    print(f"❌ Category 1040 does not exist!")
    print("\nAvailable categories (first 20):")
    for cat in Category.objects.all()[:20]:
        attrs_count = CategoryAttribute.objects.filter(category=cat).count()
        print(f"  - {cat.name} (ID: {cat.id}) - {attrs_count} attributes")
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()

