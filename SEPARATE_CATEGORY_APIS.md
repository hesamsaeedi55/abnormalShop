# Separate Category APIs with Gender Filtering

This document describes the new separate APIs for parent and child categories with gender filtering, replacing the combined API that returned both parent and child categories together.

## Overview

The original API `/api/categories/by-gender/` returned both parent and child categories in a single response. The new APIs separate this functionality into three distinct endpoints:

1. **Parent Categories Only**: `/api/categories/parents/by-gender/`
2. **Child Categories Only**: `/api/categories/children/by-gender/`
3. **Children of Specific Parent**: `/api/categories/parent/{parent_id}/children/by-gender/`

## API Endpoints

### 1. Parent Categories by Gender
**URL**: `GET /api/categories/parents/by-gender/`

**Parameters**:
- `gender_id` (optional): ID of the gender from CategoryGender table
- `gender_name` (optional): Name of the gender (men, women, unisex, general)
- `include_products` (optional): Whether to include product counts (default: true)
- `include_unassigned` (optional): Whether to include categories without gender assignment (default: false)

**Example Request**:
```
GET /api/categories/parents/by-gender/?gender_name=men
```

**Example Response**:
```json
{
    "success": true,
    "gender": {
        "id": 5,
        "name": "men",
        "display_name": "Men"
    },
    "categories": [
        {
            "id": 1031,
            "name": "اکسسوری مردانه",
            "label": "اکسسوری",
            "parent_id": null,
            "has_gender_assignment": true,
            "subcategory_count": 1,
            "gender": {
                "id": 5,
                "name": "men",
                "display_name": "Men"
            },
            "product_count": 1
        }
    ],
    "total_count": 1,
    "statistics": {
        "total_parent_categories": 4,
        "assigned_parent_categories": 4,
        "unassigned_parent_categories": 0,
        "unassigned_in_results": 0
    },
    "message": "Found 1 parent categories for gender 'Men'"
}
```

### 2. Child Categories by Gender
**URL**: `GET /api/categories/children/by-gender/`

**Parameters**:
- `gender_id` (optional): ID of the gender from CategoryGender table
- `gender_name` (optional): Name of the gender (men, women, unisex, general)
- `include_products` (optional): Whether to include product counts (default: true)
- `include_unassigned` (optional): Whether to include categories without gender assignment (default: false)

**Example Request**:
```
GET /api/categories/children/by-gender/?gender_name=men
```

**Example Response**:
```json
{
    "success": true,
    "gender": {
        "id": 5,
        "name": "men",
        "display_name": "Men"
    },
    "categories": [
        {
            "id": 1027,
            "name": "ساعت مردانه",
            "label": "ساعت",
            "parent_id": 1031,
            "parent_name": "اکسسوری مردانه",
            "parent_label": "اکسسوری",
            "has_gender_assignment": true,
            "gender": {
                "id": 5,
                "name": "men",
                "display_name": "Men"
            },
            "product_count": 1
        }
    ],
    "total_count": 1,
    "statistics": {
        "total_child_categories": 1,
        "assigned_child_categories": 1,
        "unassigned_child_categories": 0,
        "unassigned_in_results": 0
    },
    "message": "Found 1 child categories for gender 'Men'"
}
```

### 3. Children of Specific Parent by Gender
**URL**: `GET /api/categories/parent/{parent_id}/children/by-gender/`

**Parameters**:
- `parent_id` (required): ID of the parent category (in URL path)
- `gender_id` (optional): ID of the gender from CategoryGender table
- `gender_name` (optional): Name of the gender (men, women, unisex, general)
- `include_products` (optional): Whether to include product counts (default: true)
- `include_unassigned` (optional): Whether to include categories without gender assignment (default: false)

**Example Request**:
```
GET /api/categories/parent/1031/children/by-gender/?gender_name=men
```

**Example Response**:
```json
{
    "success": true,
    "parent_category": {
        "id": 1031,
        "name": "اکسسوری مردانه",
        "label": "اکسسوری"
    },
    "gender": {
        "id": 5,
        "name": "men",
        "display_name": "Men"
    },
    "categories": [
        {
            "id": 1027,
            "name": "ساعت مردانه",
            "label": "ساعت",
            "parent_id": 1031,
            "parent_name": "اکسسوری مردانه",
            "parent_label": "اکسسوری",
            "has_gender_assignment": true,
            "gender": {
                "id": 5,
                "name": "men",
                "display_name": "Men"
            },
            "product_count": 1
        }
    ],
    "total_count": 1,
    "statistics": {
        "total_child_categories": 1,
        "assigned_child_categories": 1,
        "unassigned_child_categories": 0,
        "unassigned_in_results": 0
    },
    "message": "Found 1 child categories of 'اکسسوری مردانه' for gender 'Men'"
}
```

## Key Differences from Original API

### Original API (`/api/categories/by-gender/`)
- Returns both parent and child categories in a single response
- Mixed data structure with different category types
- Harder to filter and organize on the frontend

### New Separate APIs
- **Clear separation**: Parent and child categories are in separate endpoints
- **Better organization**: Each API has a specific purpose
- **Enhanced data**: Additional fields like `subcategory_count`, `parent_name`, `parent_label`
- **Flexible filtering**: Can get children of specific parents
- **Improved statistics**: Separate statistics for parent vs child categories

## Usage Examples

### Frontend Implementation

```javascript
// Get parent categories for men
const parentCategories = await fetch('/api/categories/parents/by-gender/?gender_name=men');

// Get all child categories for men
const childCategories = await fetch('/api/categories/children/by-gender/?gender_name=men');

// Get children of a specific parent for men
const parentChildren = await fetch('/api/categories/parent/1031/children/by-gender/?gender_name=men');
```

### Swift Implementation

```swift
// Get parent categories
let parentURL = "http://localhost:8000/shop/api/categories/parents/by-gender/?gender_name=men"
let parentRequest = URLRequest(url: URL(string: parentURL)!)

// Get child categories
let childURL = "http://localhost:8000/shop/api/categories/children/by-gender/?gender_name=men"
let childRequest = URLRequest(url: URL(string: childURL)!)

// Get children of specific parent
let specificChildURL = "http://localhost:8000/shop/api/categories/parent/1031/children/by-gender/?gender_name=men"
let specificChildRequest = URLRequest(url: URL(string: specificChildURL)!)
```

## Benefits

1. **Better Performance**: Smaller, focused API responses
2. **Cleaner Data**: No mixing of parent and child categories
3. **Easier Frontend Logic**: Clear separation of concerns
4. **Flexible Filtering**: Can get children of specific parents
5. **Enhanced Metadata**: Additional fields for better UI organization
6. **Maintained Compatibility**: Original API still available for backward compatibility

## Migration Guide

If you're currently using the original `/api/categories/by-gender/` API:

1. **For parent categories**: Switch to `/api/categories/parents/by-gender/`
2. **For child categories**: Switch to `/api/categories/children/by-gender/`
3. **For specific parent children**: Use `/api/categories/parent/{parent_id}/children/by-gender/`

The original API remains available for backward compatibility, but the new separate APIs provide better organization and performance. 