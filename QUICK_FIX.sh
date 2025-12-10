#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "Quick Fix: Adding distinctive_attribute_key column"
echo "════════════════════════════════════════════════════════"
echo ""

DB_PATH="/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop/db.sqlite3"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ Database not found at: $DB_PATH"
    exit 1
fi

echo "Step 1: Adding column to database..."
sqlite3 "$DB_PATH" "ALTER TABLE shop_product ADD COLUMN distinctive_attribute_key VARCHAR(50);" 2>&1 || {
    ERROR=$?
    if [ $ERROR -eq 1 ]; then
        echo "⚠️  Column might already exist (this is OK)"
    else
        echo "❌ Error adding column"
        exit 1
    fi
}

echo ""
echo "Step 2: Verifying column was added..."
RESULT=$(sqlite3 "$DB_PATH" "PRAGMA table_info(shop_product);" | grep distinctive || echo "")

if [ -n "$RESULT" ]; then
    echo "✅ SUCCESS! Column 'distinctive_attribute_key' exists in database"
    echo ""
    echo "Column details:"
    echo "$RESULT"
else
    echo "❌ Column not found after adding. Please try manual fix."
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ FIX COMPLETE!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Restart your Django server (Ctrl+C and run again)"
echo "2. Visit: http://127.0.0.1:8003/shop/admin/products/"
echo "3. The error should be gone!"
echo ""
echo "════════════════════════════════════════════════════════"

