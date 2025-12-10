#!/usr/bin/env python
"""
Directly add the distinctive_attribute_key column to the database
"""
import os
import sys
import django

# Setup Django
project_path = os.path.join(os.path.dirname(__file__), 'myshop2', 'myshop')
sys.path.insert(0, project_path)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from django.db import connection

print("=" * 60)
print("Adding distinctive_attribute_key column to shop_product table")
print("=" * 60)

try:
    with connection.cursor() as cursor:
        # Check if column exists
        cursor.execute("PRAGMA table_info(shop_product)")
        columns = [row[1] for row in cursor.fetchall()]
        
        print(f"\nCurrent columns in shop_product: {len(columns)}")
        
        if 'distinctive_attribute_key' in columns:
            print("✅ Column 'distinctive_attribute_key' already exists!")
        else:
            print("\n❌ Column 'distinctive_attribute_key' does NOT exist. Adding it...")
            
            # Add the column
            cursor.execute("""
                ALTER TABLE shop_product 
                ADD COLUMN distinctive_attribute_key VARCHAR(50) NULL
            """)
            
            print("✅ Column added successfully!")
            
            # Verify
            cursor.execute("PRAGMA table_info(shop_product)")
            columns = [row[1] for row in cursor.fetchall()]
            
            if 'distinctive_attribute_key' in columns:
                print("✅ Verified: Column now exists in the table!")
            else:
                print("❌ Error: Column was not added!")
                
        print("\n" + "=" * 60)
        print("Now try your page again:")
        print("http://127.0.0.1:8003/shop/admin/products/")
        print("=" * 60)
        
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()

