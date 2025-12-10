from shop.models import Product, Category, Attribute, NewAttributeValue, ProductAttribute, ProductAttributeValue

cat = Category.objects.get(name='ساعت')
attr = Attribute.objects.get(key='brand')
products = Product.objects.filter(category=cat)

migrated = 0
for p in products:
    legacy = ProductAttribute.objects.filter(product=p, key='brand').first()
    if legacy:
        val = legacy.value.strip()
        if val:
            # Try to find a NewAttributeValue case-insensitively
            nav = NewAttributeValue.objects.filter(attribute=attr, value__iexact=val).first()
            if not nav:
                nav = NewAttributeValue.objects.create(attribute=attr, value=val)
            ProductAttributeValue.objects.update_or_create(
                product=p,
                attribute=attr,
                defaults={'attribute_value': nav, 'custom_value': None}
            )
            migrated += 1
print(f"Migrated {migrated} brand values to ProductAttributeValue.") 