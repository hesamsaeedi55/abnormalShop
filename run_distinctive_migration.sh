#!/bin/bash

echo "═══════════════════════════════════════════════════════"
echo "Running Migration for Distinctive Attribute Feature"
echo "═══════════════════════════════════════════════════════"

cd "/Users/hesamoddinsaeedi/Desktop/best/backup copy 64/myshop2/myshop"

echo ""
echo "Creating migration..."
python manage.py makemigrations shop

echo ""
echo "Applying migration..."
python manage.py migrate shop

echo ""
echo "✅ Migration complete!"
echo ""
echo "Now you can:"
echo "1. Go to: http://127.0.0.1:8003/suppliers/add-product/?supplier=10"
echo "2. Select a category → Enable variants → Select attributes"
echo "3. You'll see radio buttons to mark one attribute as 'distinctive'"
echo ""
echo "═══════════════════════════════════════════════════════"

