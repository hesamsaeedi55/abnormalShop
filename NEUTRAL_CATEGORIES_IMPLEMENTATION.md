# Neutral Categories Implementation

This implementation adds support for including neutral categories (general/unisex) when viewing gender-specific sections.

## What Was Implemented

### 1. Backend API Changes

#### New Parameter: `include_neutral`
- **Type**: Boolean
- **Default**: `false`
- **Description**: When `true`, includes categories with neutral gender (general/unisex) in addition to the specified gender

#### Modified Endpoints

1. **Parent Categories API**
   ```
   GET /api/categories/parents/by-gender/?gender_name=men&include_neutral=true
   ```

2. **Child Categories API**
   ```
   GET /api/categories/parent/{parent_id}/children/by-gender/?gender_name=men&include_neutral=true
   ```

### 2. Swift Code Changes

Updated `CategoryViewModel.swift` to automatically include neutral categories:
- Parent categories: `&include_neutral=true`
- Child categories: `&include_neutral=true`

## How It Works

### Before (Gender-Only)
```
GET /api/categories/parent/1031/children/by-gender/?gender_name=men
```
**Result**: Only shows categories with `gender = "men"`
- دستبند مردانه ✅
- کیف مردانه ✅
- ساعت ❌ (no gender assigned)

### After (With Neutral Categories)
```
GET /api/categories/parent/1031/children/by-gender/?gender_name=men&include_neutral=true
```
**Result**: Shows categories with `gender = "men"` + neutral categories
- دستبند مردانه ✅ (men)
- کیف مردانه ✅ (men)
- ساعت ✅ (neutral - general/unisex)

## API Response Changes

### New Statistics Field
```json
{
  "statistics": {
    "neutral_categories_included": 1,
    "total_child_categories": 3,
    "assigned_child_categories": 2,
    "unassigned_child_categories": 1
  }
}
```

### Enhanced Messages
```
"Found 3 child categories of 'اکسسوری مردانه' for gender 'Men' (including 1 neutral categories)"
```

## Usage Examples

### 1. Get Men's Parent Categories + Neutral
```swift
let url = "http://localhost:8000/shop/api/categories/parents/by-gender/?gender_name=men&include_neutral=true"
```

### 2. Get Children of Category 1031 + Neutral
```swift
let url = "http://localhost:8000/shop/api/categories/parent/1031/children/by-gender/?gender_name=men&include_neutral=true"
```

### 3. Get Women's Categories + Neutral
```swift
let url = "http://localhost:8000/shop/api/categories/parents/by-gender/?gender_name=women&include_neutral=true"
```

## Benefits

1. **Better User Experience**: Users can see all relevant categories regardless of gender assignment
2. **Flexible Navigation**: Neutral categories like "Home", "Furniture", "Chairs" are accessible from any gender section
3. **Maintains Gender Context**: Still shows gender-specific categories prominently
4. **Backward Compatible**: Existing API calls without `include_neutral` work exactly as before

## Testing

Run the test script to verify the implementation:

```bash
python test_neutral_categories.py
```

This will test:
- Parent categories with neutral inclusion
- Child categories with neutral inclusion  
- Comparison without neutral inclusion

## Database Requirements

Make sure you have these gender categories in your `CategoryGender` table:
- `men` - Male-specific categories
- `women` - Female-specific categories  
- `general` - Neutral categories (accessible to all)
- `unisex` - Neutral categories (accessible to all)

## Migration Notes

- **No database changes required**
- **No breaking changes to existing API calls**
- **New parameter is optional and defaults to false**
- **Existing Swift code will automatically benefit from neutral categories**

## Future Enhancements

1. **Smart Neutral Filtering**: Only show neutral categories that are contextually relevant
2. **User Preferences**: Allow users to toggle neutral category visibility
3. **Category Weighting**: Prioritize gender-specific categories over neutral ones
4. **Context-Aware Navigation**: Different behavior based on user's current section

