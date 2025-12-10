import os
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.myshop.settings')
django.setup()

from shop.models import Category, Product, CategoryAttribute, AttributeValue, Tag
from decimal import Decimal

def create_watch_category():
    # Create watch category if it doesn't exist
    watch_category, created = Category.objects.get_or_create(
        name='ساعت',
        defaults={'name': 'ساعت'}
    )
    
    # Define watch attributes
    watch_attributes = [
        {
            'key': 'برند',
            'type': 'select',
            'required': True,
            'values': ['Omega', 'Rolex', 'Patek Philippe', 'Audemars Piguet', 'Cartier']
        },
        {
            'key': 'سری',
            'type': 'select',
            'required': True,
            'values': ['Constellation', 'Seamaster', 'Speedmaster', 'De Ville']
        },
        {
            'key': 'جنسیت',
            'type': 'select',
            'required': True,
            'values': ['مردانه', 'زنانه', 'یونیسکس']
        },
        {
            'key': 'نوع حرکت',
            'type': 'select',
            'required': True,
            'values': ['اتوماتیک', 'کوارتز', 'دستی']
        },
        {
            'key': 'جنس بدنه',
            'type': 'select',
            'required': True,
            'values': ['استیل', 'طلای 18 عیار', 'طلای 14 عیار', 'تیتانیوم']
        },
        {
            'key': 'جنس شیشه',
            'type': 'select',
            'required': True,
            'values': ['سافایر', 'مینرال', 'پلکسی']
        },
        {
            'key': 'مقاوم در برابر آب',
            'type': 'select',
            'required': True,
            'values': ['30 متر', '50 متر', '100 متر', '200 متر', '300 متر', '600 متر']
        },
        {
            'key': 'تاریخچه',
            'type': 'text',
            'required': False
        }
    ]
    
    # Create attributes for watch category
    for attr_data in watch_attributes:
        attr, created = CategoryAttribute.objects.get_or_create(
            category=watch_category,
            key=attr_data['key'],
            defaults={
                'type': attr_data['type'],
                'required': attr_data['required']
            }
        )
        
        # Add values for select type attributes
        if attr_data['type'] == 'select' and 'values' in attr_data:
            for value in attr_data['values']:
                AttributeValue.objects.get_or_create(
                    attribute=attr,
                    value=value
                )
    
    return watch_category

def create_omega_constellation():
    # Get or create watch category
    watch_category = create_watch_category()
    
    # Create Omega Constellation watch
    product = Product.objects.create(
        name='Omega Constellation',
        description='''
        ساعت مچی Omega Constellation یکی از نمادین‌ترین مدل‌های برند اومگا است که با طراحی منحصر به فرد و کیفیت ساخت عالی شناخته می‌شود.
        
        ویژگی‌های کلیدی:
        - حرکت اتوماتیک با کالیبر 8500
        - بدنه استیل ضد زنگ
        - شیشه سافایر ضد خش
        - مقاوم در برابر آب تا عمق 100 متر
        - قابلیت نمایش تاریخ
        - بند استیل با قفل امنیتی
        ''',
        price_toman=Decimal('250000000'),  # 250 million Toman
        price_usd=Decimal('5000'),  # $5000
        category=watch_category,
        brand='Omega',
        model='Constellation',
        sku='OMG-CONST-001',
        weight=Decimal('150.00'),  # 150 grams
        dimensions='41mm x 13mm',
        warranty='2 سال گارانتی بین‌المللی',
        stock_quantity=1,
        is_active=True
    )
    
    # Add product attributes
    attributes = {
        'برند': 'Omega',
        'سری': 'Constellation',
        'جنسیت': 'مردانه',
        'نوع حرکت': 'اتوماتیک',
        'جنس بدنه': 'استیل',
        'جنس شیشه': 'سافایر',
        'مقاوم در برابر آب': '100 متر',
        'تاریخچه': 'سری Constellation اومگا در سال 1952 معرفی شد و به دلیل طراحی منحصر به فرد و کیفیت ساخت عالی، به یکی از محبوب‌ترین مدل‌های این برند تبدیل شده است.'
    }
    
    for key, value in attributes.items():
        ProductAttribute.objects.create(
            product=product,
            key=key,
            value=value
        )
    
    return product

if __name__ == '__main__':
    try:
        product = create_omega_constellation()
        print(f"Successfully created Omega Constellation watch with ID: {product.id}")
    except Exception as e:
        print(f"Error creating product: {str(e)}") 