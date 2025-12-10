# Tag-Based Similar Products System

This document describes the implementation of a tag-based similar products system for your Django e-commerce backend, designed to improve product discovery and user engagement.

## 🎯 Overview

The system uses product tags to find similar items, providing better recommendations than traditional category-based approaches. For example, products tagged with "راک" (Rock) can be grouped together regardless of their exact category.

## 🚀 New API Endpoints

### 1. Similar Products by Tags
**Endpoint:** `GET /shop/product/{product_id}/similar-by-tags/`

**Description:** Finds similar products based on tag overlap with the specified product.

**Response:**
```json
{
  "product_id": 123,
  "product_name": "Product Name",
  "similar_products": [
    {
      "id": 456,
      "name": "Similar Product",
      "price_toman": 1500000,
      "price_usd": 50.00,
      "image_url": "http://...",
      "tag_overlap": 3,
      "similarity_type": "tags",
      "tags": [
        {"id": 1, "name": "راک"},
        {"id": 2, "name": "کلاسیک"}
      ]
    }
  ],
  "total_found": 6
}
```

**Features:**
- Orders by tag overlap count (most similar first)
- Falls back to category-based similarity if no tags exist
- Includes similarity type indicator
- Returns up to 6 similar products

### 2. Products by Tags Filter
**Endpoint:** `GET /shop/api/products/by-tags/?tags=1,2,3&limit=10`

**Description:** Filters products by specific tag IDs.

**Parameters:**
- `tags`: Comma-separated tag IDs
- `limit`: Maximum number of products (default: 20, max: 100)

**Response:**
```json
{
  "tags_requested": [1, 2, 3],
  "products": [
    {
      "id": 123,
      "name": "Product Name",
      "price_toman": 1500000,
      "price_usd": 50.00,
      "image_url": "http://...",
      "tags": [{"id": 1, "name": "راک"}],
      "matching_tags": [{"id": 1, "name": "راک"}],
      "match_count": 1
    }
  ],
  "total_found": 15,
  "limit": 10
}
```

### 3. Popular Tags
**Endpoint:** `GET /shop/api/tags/popular/?limit=20&min_products=2`

**Description:** Returns popular tags ordered by product count.

**Parameters:**
- `limit`: Maximum number of tags (default: 20, max: 100)
- `min_products`: Minimum products required (default: 2)

**Response:**
```json
{
  "tags": [
    {
      "id": 1,
      "name": "راک",
      "slug": "rock",
      "product_count": 25
    }
  ],
  "total_found": 20,
  "limit": 20,
  "min_products": 2
}
```

### 4. Tag Suggestions
**Endpoint:** `GET /shop/api/tags/suggest/?q=راک&limit=10`

**Description:** Provides tag suggestions based on search query.

**Parameters:**
- `q`: Search query (minimum 2 characters)
- `limit`: Maximum number of suggestions (default: 10, max: 50)

**Response:**
```json
{
  "query": "راک",
  "tags": [
    {
      "id": 1,
      "name": "راک",
      "slug": "rock",
      "product_count": 25
    }
  ],
  "total_found": 1,
  "limit": 10
}
```

## 🔍 Enhanced Search

The existing search functionality has been enhanced to include tag-based search:

- **Text Search:** Now searches product names, SKUs, models, AND tags
- **Fuzzy Matching:** PostgreSQL users get trigram similarity for tags
- **Fallback:** Non-PostgreSQL databases use tag name matching

## 📊 Database Models

### Tag Model
```python
class Tag(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True, blank=True)
    categories = models.ManyToManyField(Category, related_name='tags', blank=True)
```

### Product-Tag Relationship
```python
class Product(models.Model):
    # ... other fields ...
    tags = models.ManyToManyField(Tag, blank=True, related_name='products')
```

## 🛠️ Management Commands

### Populate Sample Tags
```bash
cd myshop2/myshop
python manage.py populate_sample_tags
```

**Options:**
- `--clear`: Clear existing tags before creating new ones

**Sample Tags Created:**
- **Watches:** کلاسیک, ورزشی, لوکس, محدود, Professional, Classic, Sport
- **Books/Music:** راک, جاز, کلاسیک, پاپ, Rock, Jazz, Classical
- **Clothing:** کژوال, رسمی, ورزشی, Casual, Formal, Sport
- **General:** جدید, پرفروش, تخفیف, New, Best Seller, Sale

## 🧪 Testing

### Run Test Script
```bash
cd /Users/hesamoddinsaeedi/Desktop/best/backup\ copy\ 53
python test_tag_similarity.py
```

The test script will:
1. Show database statistics
2. Test all new API endpoints
3. Verify tag-based similarity functionality
4. Display sample results

## 📱 Frontend Integration

### SwiftUI Models Update
Your `ProductTest` model should include tags:

```swift
struct ProductTest: Identifiable, Decodable {
    // ... existing fields ...
    let tags: [ProductTag]?
}

struct ProductTag: Codable, Identifiable {
    let id: Int
    let name: String
}
```

### API Calls
```swift
// Get similar products
let url = "\(baseURL)/shop/product/\(productId)/similar-by-tags/"
let response = try await URLSession.shared.data(from: URL(string: url)!)
let data = try JSONDecoder().decode(SimilarProductsResponse.self, from: response.0)

// Get products by tags
let url = "\(baseURL)/shop/api/products/by-tags/?tags=\(tagIds.joined(separator: ","))"
let response = try await URLSession.shared.data(from: URL(string: url)!)
let data = try JSONDecoder().decode(ProductsByTagsResponse.self, from: response.0)
```

## 🎨 Use Cases

### 1. Music Albums
- Tag: "راک" (Rock)
- Groups rock albums across different artists, years, and subcategories
- Users can discover similar music styles

### 2. Watches
- Tags: "کلاسیک", "لوکس", "محدود"
- Connects classic luxury watches regardless of brand
- Shows limited edition items together

### 3. Clothing
- Tags: "ورزشی", "کژوال", "رسمی"
- Cross-category style matching
- Seasonal collections (تابستانی, زمستانی)

### 4. General Discovery
- Tags: "جدید", "پرفروش", "تخفیف"
- Promotional and trending items
- Special offers and limited editions

## 🔧 Configuration

### Django Settings
Ensure your Django settings include:

```python
INSTALLED_APPS = [
    # ... other apps ...
    'shop',
]

# Database optimization for tag queries
DATABASES = {
    'default': {
        # ... your database config ...
        'OPTIONS': {
            'charset': 'utf8mb4',  # For Persian text support
        }
    }
}
```

### URL Configuration
All new endpoints are automatically added to `shop/urls.py`:

```python
urlpatterns = [
    # ... existing URLs ...
    path('product/<int:product_id>/similar-by-tags/', views.get_similar_products_by_tags, name='similar_products_by_tags'),
    path('api/products/by-tags/', views.get_products_by_tags, name='products_by_tags'),
    path('api/tags/popular/', views.get_popular_tags, name='popular_tags'),
    path('api/tags/suggest/', views.get_tag_suggestions, name='tag_suggestions'),
]
```

## 📈 Performance Considerations

### Database Indexes
The system automatically uses Django's built-in optimizations:
- Foreign key indexes on tag relationships
- Many-to-many relationship optimization
- Query annotation for tag overlap counting

### Query Optimization
- Limits results to prevent excessive data transfer
- Uses `select_related` and `prefetch_related` for efficient queries
- Implements pagination for large result sets

## 🚨 Security Features

### Input Validation
- Tag ID validation (must be integers)
- Query length limits (2-100 characters)
- Result count limits (max 100 products, 1000 pages)

### SQL Injection Protection
- Uses Django ORM for all database queries
- Parameterized queries for all user inputs
- Input sanitization and validation

## 🔄 Migration Path

### Phase 1: Backend Implementation ✅
- [x] Tag-based similar products API
- [x] Products by tags filter
- [x] Popular tags endpoint
- [x] Tag suggestions
- [x] Enhanced search with tags

### Phase 2: Data Population
- [ ] Run `populate_sample_tags` command
- [ ] Assign tags to existing products
- [ ] Test with real data

### Phase 3: Frontend Integration
- [ ] Update SwiftUI models
- [ ] Implement similar products UI
- [ ] Add tag-based filtering
- [ ] Tag display in product cards

### Phase 4: Advanced Features
- [ ] Tag analytics and insights
- [ ] Personalized tag recommendations
- [ ] Tag-based user preferences
- [ ] A/B testing for recommendations

## 🐛 Troubleshooting

### Common Issues

1. **No similar products found**
   - Check if products have tags assigned
   - Verify tag relationships in admin
   - Run `populate_sample_tags` command

2. **Performance issues**
   - Ensure database indexes are created
   - Check query execution plans
   - Monitor database performance

3. **Tag search not working**
   - Verify tag names in database
   - Check character encoding (UTF-8)
   - Test with simple tag names first

### Debug Commands
```bash
# Check tag statistics
python manage.py shell
>>> from shop.models import Tag, Product
>>> Tag.objects.count()
>>> Product.objects.filter(tags__isnull=False).count()

# Test specific tag
>>> tag = Tag.objects.get(name='راک')
>>> tag.products.count()
```

## 📞 Support

For issues or questions:
1. Check the test script output
2. Review Django debug logs
3. Verify database connectivity
4. Test individual API endpoints

## 🎉 Benefits

This tag-based system provides:
- **Better Discovery:** Users find related products more easily
- **Increased Engagement:** More time spent exploring your catalog
- **Higher Conversion:** Better product recommendations
- **Persian Market Relevance:** Culturally appropriate tagging
- **Scalability:** Easy to add new tags and categories
- **Flexibility:** Cross-category product relationships

The system is designed to work seamlessly with your existing Django infrastructure while providing powerful new capabilities for product discovery and user experience.


