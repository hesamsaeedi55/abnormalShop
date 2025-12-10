#!/bin/bash

echo "Adding distinctive_attribute_key column..."

cd "/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop"

python manage.py shell <<'EOF'
from django.db import connection

with connection.cursor() as cursor:
    # Check if column exists
    cursor.execute("PRAGMA table_info(shop_product)")
    columns = [row[1] for row in cursor.fetchall()]
    
    if 'distinctive_attribute_key' in columns:
        print("✅ Column already exists!")
    else:
        print("Adding column...")
        cursor.execute("ALTER TABLE shop_product ADD COLUMN distinctive_attribute_key VARCHAR(50) NULL")
        print("✅ Column added!")
        
print("\n✅ Done! Refresh your page now.")
EOF

