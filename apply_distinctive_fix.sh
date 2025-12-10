#!/bin/bash

echo "═══════════════════════════════════════════════════════"
echo "Applying Distinctive Attribute Migration"
echo "═══════════════════════════════════════════════════════"

cd "/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop"

echo ""
echo "Step 1: Checking migration..."
python manage.py showmigrations shop | tail -5

echo ""
echo "Step 2: Applying migration..."
python manage.py migrate shop

echo ""
echo "✅ Done!"
echo ""
echo "The error should be fixed now. Try creating a product with variants again."
echo ""
echo "═══════════════════════════════════════════════════════"

