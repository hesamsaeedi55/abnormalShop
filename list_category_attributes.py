from shop.models import Category, CategoryAttribute
cat = Category.objects.get(name='ساعت')
for ca in CategoryAttribute.objects.filter(category=cat):
    print(f'{ca.id}: {ca.key}') 