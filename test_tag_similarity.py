#!/usr/bin/env python3
"""
Test script for tag-based similar products functionality
Run this script to test the new Django endpoints
"""

import os
import sys
import django
from django.test import RequestFactory
from django.contrib.auth.models import User

# Add the Django project to the Python path
sys.path.append('/Users/hesamoddinsaeedi/Desktop/best/backup copy 53/myshop2/myshop')

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'myshop.settings')
django.setup()

from shop.models import Product, Tag, Category
from shop.views import get_similar_products_by_tags, get_products_by_tags, get_popular_tags, get_tag_suggestions

def test_tag_similarity():
    """Test the tag-based similar products functionality"""
    print("🧪 Testing Tag-Based Similar Products Functionality")
    print("=" * 60)
    
    # Create a mock request
    factory = RequestFactory()
    
    # Test 1: Get popular tags
    print("\n1️⃣ Testing Popular Tags API...")
    request = factory.get('/api/tags/popular/?limit=5&min_products=1')
    response = get_popular_tags(request)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Found {data['total_found']} popular tags")
        for tag in data['tags'][:3]:  # Show first 3
            print(f"  - {tag['name']}: {tag['product_count']} products")
    else:
        print(f"Error: {response.content.decode()}")
    
    # Test 2: Get tag suggestions
    print("\n2️⃣ Testing Tag Suggestions API...")
    request = factory.get('/api/tags/suggest/?q=راک&limit=5')
    response = get_tag_suggestions(request)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print(f"Found {data['total_found']} tags matching 'راک'")
        for tag in data['tags']:
            print(f"  - {tag['name']}: {tag['product_count']} products")
    else:
        print(f"Error: {response.content.decode()}")
    
    # Test 3: Get products by tags
    print("\n3️⃣ Testing Products by Tags API...")
    # First get some tag IDs
    tags = Tag.objects.all()[:3]
    if tags:
        tag_ids = [tag.id for tag in tags]
        tag_names = [tag.name for tag in tags]
        print(f"Testing with tags: {', '.join(tag_names)}")
        
        request = factory.get(f'/api/products/by-tags/?tags={",".join(map(str, tag_ids))}&limit=5')
        response = get_products_by_tags(request)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Found {data['total_found']} products with these tags")
            for product in data['products'][:2]:  # Show first 2
                print(f"  - {product['name']}: {product['match_count']} matching tags")
        else:
            print(f"Error: {response.content.decode()}")
    else:
        print("No tags found in database")
    
    # Test 4: Get similar products by tags for a specific product
    print("\n4️⃣ Testing Similar Products by Tags API...")
    products = Product.objects.filter(tags__isnull=False).distinct()[:1]
    if products:
        product = products[0]
        print(f"Testing with product: {product.name}")
        print(f"Product tags: {[tag.name for tag in product.tags.all()]}")
        
        request = factory.get(f'/product/{product.id}/similar-by-tags/')
        response = get_similar_products_by_tags(request, product.id)
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Found {data['total_found']} similar products")
            for similar in data['similar_products'][:2]:  # Show first 2
                print(f"  - {similar['name']}: {similar['tag_overlap']} tag overlap")
        else:
            print(f"Error: {response.content.decode()}")
    else:
        print("No products with tags found in database")
    
    print("\n✅ Tag similarity testing completed!")

def show_database_stats():
    """Show current database statistics for tags and products"""
    print("\n📊 Database Statistics")
    print("=" * 40)
    
    total_products = Product.objects.count()
    products_with_tags = Product.objects.filter(tags__isnull=False).distinct().count()
    total_tags = Tag.objects.count()
    
    print(f"Total Products: {total_products}")
    print(f"Products with Tags: {products_with_tags}")
    print(f"Total Tags: {total_tags}")
    
    if total_tags > 0:
        print(f"Tag Coverage: {(products_with_tags/total_products)*100:.1f}%")
        
        # Show some sample tags
        print("\nSample Tags:")
        for tag in Tag.objects.all()[:5]:
            product_count = tag.products.count()
            print(f"  - {tag.name}: {product_count} products")
    
    if total_products > 0:
        print("\nSample Products with Tags:")
        for product in Product.objects.filter(tags__isnull=False).distinct()[:3]:
            tags = [tag.name for tag in product.tags.all()]
            print(f"  - {product.name}: {', '.join(tags)}")

if __name__ == "__main__":
    try:
        show_database_stats()
        test_tag_similarity()
    except Exception as e:
        print(f"❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()


