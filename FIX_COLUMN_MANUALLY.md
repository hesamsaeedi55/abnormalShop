# Fix: Add distinctive_attribute_key Column

## The Problem
The database is missing the `distinctive_attribute_key` column in the `shop_product` table.

## Quick Fix (Option 1 - Recommended)

Open your terminal and run these commands one by one:

```bash
# Navigate to your project
cd "/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop"

# Add the column using sqlite3
sqlite3 db.sqlite3 "ALTER TABLE shop_product ADD COLUMN distinctive_attribute_key VARCHAR(50);"

# Verify it was added
sqlite3 db.sqlite3 "PRAGMA table_info(shop_product);" | grep distinctive
```

If you see output with "distinctive_attribute_key", it worked!

## Alternative Fix (Option 2 - Using Python)

```bash
cd "/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop"

python3 << 'EOF'
import sqlite3
conn = sqlite3.connect('db.sqlite3')
cursor = conn.cursor()

try:
    cursor.execute("ALTER TABLE shop_product ADD COLUMN distinctive_attribute_key VARCHAR(50)")
    conn.commit()
    print("✅ Column added successfully!")
except sqlite3.OperationalError as e:
    if "duplicate column" in str(e).lower():
        print("✅ Column already exists!")
    else:
        print(f"❌ Error: {e}")
finally:
    conn.close()
EOF
```

## Alternative Fix (Option 3 - Using Django)

```bash
cd "/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop"

python manage.py shell << 'EOF'
from django.db import connection

with connection.cursor() as cursor:
    try:
        cursor.execute("ALTER TABLE shop_product ADD COLUMN distinctive_attribute_key VARCHAR(50)")
        print("✅ Column added!")
    except Exception as e:
        if "duplicate column" in str(e).lower():
            print("✅ Column already exists!")
        else:
            print(f"❌ Error: {e}")
EOF
```

## After Running One of These Options

1. Restart your Django development server:
   ```bash
   # Press Ctrl+C to stop the server
   # Then start it again:
   python manage.py runserver 8003
   ```

2. Try accessing these URLs again:
   - http://127.0.0.1:8003/shop/admin/products/
   - http://127.0.0.1:8003/suppliers/add-product/?supplier=10

3. The error should be gone! ✅

## To Verify It Worked

Run this command:
```bash
cd "/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop"
sqlite3 db.sqlite3 "SELECT sql FROM sqlite_master WHERE type='table' AND name='shop_product';" | grep distinctive
```

If you see `distinctive_attribute_key` in the output, the column exists and you're good to go!

## If You Get "duplicate column name" Error

That's actually good! It means the column already exists. Just restart your Django server and try again.

## What This Column Does

This column stores which variant attribute (like "color" or "size") is the "distinctive" one for products with variants. It's used by the API to tell mobile apps which attribute should be shown prominently in the UI.

