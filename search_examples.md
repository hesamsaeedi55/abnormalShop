# Search API Examples for Product Names and Brands

This guide shows how to use your database's search APIs to find products by name or brand.

## 1. Simple Text Search API

### Endpoint
```
GET /shop/api/products/search/
```

### Parameters
- `q` - Search query (product name, brand, model, SKU)
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 24)
- `sort_by` - Sort order: `name`, `-name`, `price`, `-price`, `date`, `-date`
- `fuzzy` - Enable fuzzy matching (default: true)
- `category` - Filter by category ID (optional)

### Example 1: Search for "Rolex" watches
```bash
curl "http://yourdomain.com/shop/api/products/search/?q=Rolex&per_page=12&sort_by=name"
```

**Response:**
```json
{
  "products": [
    {
      "id": 123,
      "name": "Rolex Submariner Date",
      "brand": "Rolex",
      "model": "116610LN",
      "sku": "ROLEX-SUB-001",
      "price_toman": 850000000,
      "price_usd": 8500,
      "category": {
        "id": 1,
        "name": "ساعت"
      },
      "images": [
        {
          "id": 456,
          "url": "http://yourdomain.com/media/products/rolex_submariner.jpg",
          "is_primary": true,
          "order": 1
        }
      ],
      "attributes": [
        {
          "key": "نوع موومنت",
          "value": "اتوماتیک"
        },
        {
          "key": "جنس قاب",
          "value": "فولاد ضد زنگ"
        }
      ]
    }
  ],
  "pagination": {
    "total_pages": 3,
    "current_page": 1,
    "total_items": 67,
    "has_next": true,
    "has_previous": false
  }
}
```

### Example 2: Search for "ساعت" (watch) in Persian
```bash
curl "http://yourdomain.com/shop/api/products/search/?q=ساعت&category=1&sort_by=-price"
```

### Example 3: Search with fuzzy matching disabled
```bash
curl "http://yourdomain.com/shop/api/products/search/?q=Omega&fuzzy=false&sort_by=date"
```

## 2. Advanced Search API

### Endpoint
```
GET /shop/api/products/advanced-search/
```

### Parameters
- `q` - Search query
- `min_price_toman` / `max_price_toman` - Price range in Toman
- `min_price_usd` / `max_price_usd` - Price range in USD
- `category` - Category ID
- `tags` - Multiple tag IDs
- `in_stock` - Stock availability (true/false)
- `is_active` - Active status (true/false)
- `attr_[key]` - Attribute filters
- `sort_by` - Sort order
- `page` - Page number
- `per_page` - Items per page

### Example 1: Search for luxury watches with price range
```bash
curl "http://yourdomain.com/shop/api/products/advanced-search/?q=ساعت&min_price_usd=1000&max_price_usd=10000&category=1&sort_by=-price"
```

### Example 2: Search for specific brand with stock filter
```bash
curl "http://yourdomain.com/shop/api/products/advanced-search/?q=Cartier&in_stock=true&attr_نوع موومنت=اتوماتیک"
```

## 3. General Products Filter API

### Endpoint
```
GET /shop/api/products/filter/
```

### Parameters
- `q` or `search` - Search query
- `category` - Category ID
- `brand` - Brand name (multiple values supported)
- `model` - Model name
- `price__gte` / `price__lte` - Price range
- `is_new_arrival` - New arrivals filter
- `page` - Page number
- `per_page` - Items per page

### Example 1: Filter by multiple brands
```bash
curl "http://yourdomain.com/shop/api/products/filter/?brand=Rolex&brand=Omega&brand=Cartier&category=1"
```

### Example 2: Search with price and category filters
```bash
curl "http://yourdomain.com/shop/api/products/filter/?q=ساعت&category=1&price__gte=1000000&price__lte=5000000"
```

## 4. Category-Specific Search

### Endpoint
```
GET /shop/api/category/{category_id}/filter/
```

### Example: Search within "ساعت" category
```bash
curl "http://yourdomain.com/shop/api/category/1/filter/?q=Rolex&brand=Rolex&attr_نوع موومنت=اتوماتیک"
```

## 5. JavaScript/Frontend Examples

### Simple Search Function
```javascript
async function searchProducts(query, options = {}) {
    const params = new URLSearchParams({
        q: query,
        page: options.page || 1,
        per_page: options.perPage || 24,
        sort_by: options.sortBy || '-date',
        fuzzy: options.fuzzy !== false ? 'true' : 'false'
    });
    
    if (options.categoryId) {
        params.append('category', options.categoryId);
    }
    
    try {
        const response = await fetch(`/shop/api/products/search/?${params}`);
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Search failed:', error);
        throw error;
    }
}

// Usage examples:
// Search for Rolex watches
searchProducts('Rolex', { categoryId: 1, sortBy: 'name' })
    .then(data => console.log('Found products:', data.products));

// Search for watches in Persian
searchProducts('ساعت', { perPage: 50, sortBy: '-price' })
    .then(data => console.log('Total found:', data.pagination.total_items));
```

### Advanced Search Function
```javascript
async function advancedSearch(criteria) {
    const params = new URLSearchParams();
    
    if (criteria.query) params.append('q', criteria.query);
    if (criteria.minPrice) params.append('min_price_usd', criteria.minPrice);
    if (criteria.maxPrice) params.append('max_price_usd', criteria.maxPrice);
    if (criteria.category) params.append('category', criteria.category);
    if (criteria.inStock !== undefined) params.append('in_stock', criteria.inStock);
    if (criteria.sortBy) params.append('sort_by', criteria.sortBy);
    if (criteria.page) params.append('page', criteria.page);
    if (criteria.perPage) params.append('per_page', criteria.perPage);
    
    // Add attribute filters
    if (criteria.attributes) {
        Object.entries(criteria.attributes).forEach(([key, value]) => {
            params.append(`attr_${key}`, value);
        });
    }
    
    try {
        const response = await fetch(`/shop/api/products/advanced-search/?${params}`);
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Advanced search failed:', error);
        throw error;
    }
}

// Usage example:
advancedSearch({
    query: 'ساعت',
    minPrice: 1000,
    maxPrice: 10000,
    category: 1,
    inStock: true,
    attributes: {
        'نوع موومنت': 'اتوماتیک',
        'جنس قاب': 'فولاد ضد زنگ'
    },
    sortBy: '-price',
    perPage: 20
}).then(data => {
    console.log('Luxury watches found:', data.products);
    console.log('Total pages:', data.pagination.total_pages);
});
```

## 6. Python/Django Examples

### Using the Search APIs in Django Views
```python
import requests
import json

def search_products_from_view(request):
    """Example of calling search API from another Django view"""
    
    # Simple search
    search_params = {
        'q': request.GET.get('q', ''),
        'category': request.GET.get('category', ''),
        'page': request.GET.get('page', 1),
        'per_page': request.GET.get('per_page', 24)
    }
    
    # Build URL
    base_url = request.build_absolute_uri('/shop/api/products/search/')
    response = requests.get(base_url, params=search_params)
    
    if response.status_code == 200:
        search_results = response.json()
        return JsonResponse(search_results)
    else:
        return JsonResponse({'error': 'Search failed'}, status=500)

def search_by_brand(request, brand_name):
    """Search products by specific brand"""
    
    search_params = {
        'q': brand_name,
        'per_page': 50,
        'sort_by': 'name'
    }
    
    base_url = request.build_absolute_uri('/shop/api/products/search/')
    response = requests.get(base_url, params=search_params)
    
    if response.status_code == 200:
        return JsonResponse(response.json())
    else:
        return JsonResponse({'error': 'Brand search failed'}, status=500)
```

## 7. Testing the APIs

### Test with curl commands:
```bash
# Test simple search
curl "http://localhost:8000/shop/api/products/search/?q=test"

# Test advanced search
curl "http://localhost:8000/shop/api/products/advanced-search/?q=test&min_price_usd=100"

# Test category filter
curl "http://localhost:8000/shop/api/products/filter/?category=1&q=ساعت"
```

### Test with browser:
- Navigate to: `http://localhost:8000/shop/api/products/search/?q=ساعت`
- Navigate to: `http://localhost:8000/shop/api/products/advanced-search/?q=Rolex&category=1`

## Key Features Summary

✅ **Text Search**: Search in product names, descriptions, SKU, brand, and model  
✅ **Fuzzy Matching**: PostgreSQL trigram similarity for better results  
✅ **Category Filtering**: Filter results by specific categories  
✅ **Price Filtering**: Range filtering in both Toman and USD  
✅ **Attribute Filtering**: Filter by product attributes  
✅ **Pagination**: Configurable page sizes and navigation  
✅ **Sorting**: Multiple sort options (name, price, date)  
✅ **Stock Filtering**: Filter by availability  
✅ **Multi-language**: Support for Persian and English text  

These APIs provide comprehensive search functionality for your e-commerce platform, allowing users to find products efficiently by name, brand, or any other criteria.


