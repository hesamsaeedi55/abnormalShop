from django.core.management.base import BaseCommand
from shop.models import Category, CategoryAttribute, AttributeValue

class Command(BaseCommand):
    help = 'Set up detailed watch attributes with Persian labels and values'

    def handle(self, *args, **options):
        self.stdout.write("🏗️ Setting up detailed watch attributes...")
        
        # Get watch subcategories
        mens_watches = Category.objects.filter(name="ساعت مردانه").first()
        womens_watches = Category.objects.filter(name="ساعت زنانه").first()
        unisex_watches = Category.objects.filter(name="ساعت یونیسکس").first()
        
        watch_categories = [cat for cat in [mens_watches, womens_watches, unisex_watches] if cat]
        
        if not watch_categories:
            self.stdout.write(self.style.ERROR("❌ No watch subcategories found. Please run setup_gender_categories first."))
            return
        
        # Define comprehensive watch attributes
        watch_attributes = [
            {
                'key': 'برند',
                'label_fa': 'برند',
                'type': 'select',
                'required': True,
                'values': [
                    'رولکس', 'اومگا', 'پاتک فیلیپ', 'اودمار پیگه', 'کارتیه',
                    'برایتلینگ', 'تگ هویر', 'IWC', 'جگر لکولتر', 'واشرون کنستانتین',
                    'لانگه اند زونه', 'بلانپین', 'اوریس', 'لونژین', 'تیسو',
                    'سیکو', 'سیتیزن', 'کاسیو', 'اپل', 'سامسونگ', 'گارمین',
                    'کنستانتین چایکین', 'ریچارد میل', 'هابلوت', 'پنرای'
                ]
            },
            {
                'key': 'جنس_شیشه',
                'label_fa': 'جنس شیشه',
                'type': 'select',
                'required': True,
                'values': [
                    'سافایر', 'سافایر ضد انعکاس', 'مینرال کریستال', 
                    'پلکسی گلاس', 'گوریلا گلاس', 'سافایر دو طرفه ضد انعکاس'
                ]
            },
            {
                'key': 'نوع_حرکت',
                'label_fa': 'نوع حرکت',
                'type': 'select',
                'required': True,
                'values': [
                    'اتوماتیک', 'کوارتز', 'دستی (مکانیکی)', 'کوارتز خورشیدی',
                    'اتوماتیک کرونوگراف', 'کوارتز کرونوگراف', 'اسمارت واچ',
                    'کینتیک (سیکو)', 'ایکو درایو (سیتیزن)'
                ]
            },
            {
                'key': 'جنسیت',
                'label_fa': 'جنسیت',
                'type': 'select',
                'required': True,
                'values': ['مردانه', 'زنانه', 'یونیسکس']
            },
            {
                'key': 'مقاومت_آب',
                'label_fa': 'مقاومت در برابر آب (متر)',
                'type': 'select',
                'required': True,
                'values': [
                    '30 متر (3 ATM)', '50 متر (5 ATM)', '100 متر (10 ATM)',
                    '200 متر (20 ATM)', '300 متر (30 ATM)', '500 متر (50 ATM)',
                    '1000 متر (100 ATM)', '1500 متر (150 ATM)', 'غیر ضد آب'
                ]
            },
            {
                'key': 'سایز_قاب',
                'label_fa': 'اندازه قاب (میلی‌متر)',
                'type': 'select',
                'required': True,
                'values': [
                    '26mm', '28mm', '30mm', '32mm', '34mm', '36mm', '38mm',
                    '39mm', '40mm', '41mm', '42mm', '43mm', '44mm', '45mm',
                    '46mm', '47mm', '48mm', '49mm', '50mm'
                ]
            },
            {
                'key': 'کشور_سازنده',
                'label_fa': 'کشور سازنده',
                'type': 'select',
                'required': True,
                'values': [
                    'سوئیس', 'آلمان', 'ژاپن', 'آمریکا', 'انگلستان', 'فرانسه',
                    'ایتالیا', 'کره جنوبی', 'چین', 'هنگ کنگ', 'روسیه', 'دانمارک'
                ]
            },
            {
                'key': 'سال_تولید',
                'label_fa': 'سال تولید',
                'type': 'select',
                'required': False,
                'values': [
                    '2024', '2023', '2022', '2021', '2020', '2019', '2018',
                    '2017', '2016', '2015', '2014', '2013', '2012', '2011',
                    '2010', '2009', '2008', '2007', '2006', '2005',
                    'قبل از 2005', 'مشخص نیست'
                ]
            },
            {
                'key': 'وضعیت',
                'label_fa': 'وضعیت',
                'type': 'select',
                'required': True,
                'values': [
                    'نو (برند جدید)', 'نو (نمایشگاهی)', 'دست دوم عالی',
                    'دست دوم خوب', 'دست دوم متوسط', 'نیاز به تعمیر',
                    'کلکسیونی', 'ونتیج'
                ]
            },
            {
                'key': 'متعلقات',
                'label_fa': 'جعبه، کارت و متعلقات',
                'type': 'multiselect',
                'required': False,
                'values': [
                    'جعبه اصلی', 'کارت گارانتی', 'دفترچه راهنما', 'برگ خرید',
                    'بند اضافی', 'ابزار تنظیم بند', 'کیسه محافظ', 'گواهی اصالت',
                    'سرویس ریکورد', 'تگ اصلی', 'بدون متعلقات'
                ]
            },
            {
                'key': 'رنگ_صفحه',
                'label_fa': 'رنگ صفحه',
                'type': 'select',
                'required': True,
                'values': [
                    'مشکی', 'سفید', 'آبی', 'قرمز', 'سبز', 'طلایی', 'نقره‌ای',
                    'قهوه‌ای', 'خاکستری', 'بنفش', 'صورتی', 'نارنجی', 'زرد',
                    'شامپاینی', 'گیلوشه', 'برونزی', 'دودی', 'پرل', 'مادر مروارید',
                    'کربن فایبر', 'رادیوم', 'سان ری (آفتابی)'
                ]
            },
            {
                'key': 'جنس_بند',
                'label_fa': 'جنس بند',
                'type': 'select',
                'required': True,
                'values': [
                    'استیل ضد زنگ', 'چرم طبیعی', 'چرم مصنوعی', 'طلای 18 عیار',
                    'طلای 14 عیار', 'تیتانیوم', 'سرامیک', 'کربن فایبر',
                    'نایلون', 'سیلیکون', 'لاستیک', 'بافت فلزی', 'پلاتین',
                    'آلومینیوم', 'برنز', 'چرم کروکودیل', 'چرم شترمرغ', 'بامبو'
                ]
            },
            {
                'key': 'شکل_قاب',
                'label_fa': 'شکل قاب',
                'type': 'select',
                'required': True,
                'values': [
                    'گرد', 'مربع', 'مستطیل', 'بیضی', 'کوشن', 'تانک',
                    'بارل', 'کشتی', 'هگزاگون', 'اکتاگون', 'پیلو', 'تونو'
                ]
            },
            {
                'key': 'امکانات_اضافی',
                'label_fa': 'امکانات اضافی',
                'type': 'multiselect',
                'required': False,
                'values': [
                    'کرونوگراف', 'تاریخ', 'روز هفته', 'ماه', 'فاز ماه', 'GMT',
                    'دوم منطقه زمانی', 'آلارم', 'تایمر', 'استپ واچ', 'ضد مغناطیس',
                    'هلیوم اسکیپ ولو', 'تاکیمتر', 'تله متر', 'پالس متر',
                    'کمپاس', 'آلتیمتر', 'بارومتر', 'ترمومتر', 'GPS',
                    'ضربان سنج', 'شمارش قدم', 'کنترل موزیک', 'پاسخ تماس',
                    'NFC', 'وای فای', 'بلوتوث', 'نمایش اعلانات',
                    'پاور ریزرو نمایشگر', 'سکند جامپر', 'هک سکند',
                    'لومینوس (شب تاب)', 'روتیتینگ بزل', 'سافایر کریستال کیس بک'
                ]
            }
        ]
        
        # Apply attributes to all watch subcategories
        for category in watch_categories:
            self.stdout.write(f"\n📂 Setting up attributes for: {category.name}")
            
            # Clear existing attributes to avoid duplicates
            category.category_attributes.all().delete()
            
            for i, attr_data in enumerate(watch_attributes):
                # Create CategoryAttribute
                category_attr, created = CategoryAttribute.objects.get_or_create(
                    category=category,
                    key=attr_data['key'],
                    defaults={
                        'type': attr_data['type'],
                        'required': attr_data['required'],
                        'display_order': i,
                        'label_fa': attr_data['label_fa']
                    }
                )
                
                if created:
                    self.stdout.write(f"   ✅ Added attribute: {attr_data['label_fa']} ({attr_data['key']})")
                else:
                    # Update existing attribute
                    category_attr.type = attr_data['type']
                    category_attr.required = attr_data['required']
                    category_attr.display_order = i
                    category_attr.label_fa = attr_data['label_fa']
                    category_attr.save()
                    self.stdout.write(f"   🔄 Updated attribute: {attr_data['label_fa']} ({attr_data['key']})")
                
                # Add predefined values
                if 'values' in attr_data and attr_data['values']:
                    # Clear existing values
                    category_attr.values.all().delete()
                    
                    for j, value in enumerate(attr_data['values']):
                        AttributeValue.objects.create(
                            attribute=category_attr,
                            value=value,
                            display_order=j
                        )
                    
                    self.stdout.write(f"      📋 Added {len(attr_data['values'])} predefined values")
        
        self.stdout.write(self.style.SUCCESS(f"\n🎉 Successfully set up detailed watch attributes!"))
        self.stdout.write(f"\n📊 Summary:")
        self.stdout.write(f"   - Categories updated: {len(watch_categories)}")
        self.stdout.write(f"   - Attributes per category: {len(watch_attributes)}")
        
        total_values = sum(len(attr.get('values', [])) for attr in watch_attributes)
        self.stdout.write(f"   - Total predefined values: {total_values}")
        
        self.stdout.write(f"\n💡 Attributes include:")
        for attr in watch_attributes:
            required_text = "✅ Required" if attr['required'] else "⚪ Optional"
            self.stdout.write(f"   • {attr['label_fa']} ({attr['type']}) {required_text}") 