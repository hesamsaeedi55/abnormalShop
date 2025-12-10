# Distinctive Attribute Implementation

## Summary
Added ability to mark one variant attribute as "distinctive" when creating products with variants. This allows the API to indicate which attribute (e.g., color) should be used to distinguish between product variants.

## Changes Made

### 1. Database Model Update
**File**: `myshop2/myshop/shop/models.py`

Added `distinctive_attribute_key` field to Product model:
```python
distinctive_attribute_key = models.CharField(
    max_length=50, 
    blank=True, 
    null=True,
    verbose_name='ویژگی متمایز',
    help_text='ویژگی‌ای که برای تشخیص انواع محصول استفاده می‌شود (مثلاً رنگ)'
)
```

### 2. API Update
**File**: `myshop2/myshop/shop/views.py` (line ~2285)

- **Removed**: Variant-level `isDistinctive` field (it was junk)
- **Updated**: Now reads `distinctive_attribute_key` from product
- **Logic**: Only the attribute matching `product.distinctive_attribute_key` gets `isDistinctive: true`

```python
# Get the distinctive attribute key from product metadata
distinctive_key = getattr(product, 'distinctive_attribute_key', None)

for key, value in variant.attributes.items():
    # Check if this specific attribute is the distinctive one
    is_distinctive = (distinctive_key and key == distinctive_key)
    attributes_array.append({
        'key': key,
        'value': value,
        'isDistinctive': is_distinctive
    })
```

**API Output Before**:
```json
{
    "isDistinctive": false,  // ❌ This was junk at variant level
    "attributes": [
        {"key": "color", "isDistinctive": true}
    ]
}
```

**API Output Now**:
```json
{
    "attributes": [
        {"key": "color", "isDistinctive": true},
        {"key": "size", "isDistinctive": false}
    ]
}
```

### 3. Frontend UI Update
**File**: `myshop2/myshop/suppliers/templates/suppliers/add_product.html`

#### Added Radio Button for Each Variant Attribute:
```html
<div style="margin-top: 0.75rem; padding-top: 0.75rem; border-top: 1px solid #dee2e6;">
    <label style="display: flex; align-items: center; justify-content: center; gap: 0.5rem;">
        <input type="radio" 
               name="distinctive_attribute" 
               value="${attr.key}" 
               class="distinctive-radio"
               onclick="event.stopPropagation(); handleDistinctiveSelection('${attr.key}');">
        <span>ویژگی متمایز</span>
    </label>
</div>
```

#### Auto-Select Logic:
- If only **1 variant attribute** is selected → automatically mark it as distinctive
- If **multiple attributes** are selected → user must choose which one is distinctive
- **Radio button behavior** → only ONE attribute can be distinctive at a time

```javascript
// ✨ AUTO-SELECT distinctive if only one attribute is selected
if (allSelected.length === 1) {
    const radio = allSelected[0].querySelector('.distinctive-radio');
    if (radio && !radio.checked) {
        radio.checked = true;
        console.log('🎯 Auto-selected as distinctive (only one attribute):', attrName);
    }
}
```

### 4. Form Submission Update
**File**: Same file, `prepareFormSubmission()` function

Added code to capture the distinctive attribute and send it to backend:

```javascript
// ✨ Add distinctive attribute key
const distinctiveRadio = document.querySelector('.distinctive-radio:checked');
if (distinctiveRadio) {
    const distinctiveKey = distinctiveRadio.value;
    
    const distinctiveInput = document.createElement('input');
    distinctiveInput.type = 'hidden';
    distinctiveInput.name = 'distinctive_attribute';
    distinctiveInput.value = distinctiveKey;
    form.appendChild(distinctiveInput);
    
    console.log('✅ PREP: Added distinctive_attribute input with value:', distinctiveKey);
}
```

### 5. Backend Save Logic
**File**: `myshop2/myshop/suppliers/views.py` (line ~888)

Added code to save the distinctive attribute key:

```python
# ✨ Save distinctive attribute key
distinctive_attr_key = request.POST.get('distinctive_attribute', '')
if distinctive_attr_key:
    product.distinctive_attribute_key = distinctive_attr_key
    product.save(update_fields=['distinctive_attribute_key'])
    print(f"✅ Saved distinctive attribute key: {distinctive_attr_key}")
else:
    # Clear distinctive attribute if none selected
    product.distinctive_attribute_key = None
    product.save(update_fields=['distinctive_attribute_key'])
    print("🔧 Cleared distinctive attribute key")
```

## How to Use

### For Suppliers/Admins:

1. Go to add product page: `http://127.0.0.1:8003/suppliers/add-product/?supplier=10`
2. Select a category with attributes
3. Enable "محصول دارای نوع‌های مختلف است" (Has Variants) checkbox
4. Select variant attributes (e.g., color, size)
5. **NEW**: For each selected attribute, a radio button appears: "ویژگی متمایز"
6. Select which attribute is distinctive (only one can be selected)
7. If you select only one attribute, it's automatically marked as distinctive
8. Create variants and save product

### For API Consumers (Swift/Mobile):

```swift
// In your variant model
struct Variant {
    let attributes: [VariantAttribute]
}

struct VariantAttribute {
    let key: String
    let value: String
    let isDistinctive: Bool  // ← Use this to determine which attribute to show prominently
}

// Example: Show distinctive attribute (color) prominently in UI
for attribute in variant.attributes {
    if attribute.isDistinctive {
        // This is the main differentiating attribute (e.g., color)
        // Show it prominently in the variant selector
        print("Main attribute: \(attribute.key) = \(attribute.value)")
    }
}
```

## Database Migration

**Required**: Run migration to add the new field:

```bash
cd myshop2/myshop
python manage.py makemigrations shop
python manage.py migrate shop
```

## Testing

### Test Case 1: Single Variant Attribute
1. Create product with variants
2. Select only "color" as variant attribute
3. **Expected**: "color" is automatically marked as distinctive
4. Save product
5. Check API: `/shop/api/product/{id}/detail/`
6. **Expected**: Color attribute has `isDistinctive: true`

### Test Case 2: Multiple Variant Attributes
1. Create product with variants
2. Select both "color" and "size" as variant attributes
3. Manually select "color" as distinctive
4. **Expected**: Only color radio button is checked
5. Save product
6. Check API
7. **Expected**: Only color has `isDistinctive: true`, size has `isDistinctive: false`

### Test Case 3: API Response Verification
Compare product 376 before and after:

**Before** (with junk field):
```json
{
    "variants": [{
        "isDistinctive": false,  // ❌ Junk
        "attributes": [
            {"key": "color", "value": "مشکی", "isDistinctive": true}
        ]
    }]
}
```

**After** (cleaned up):
```json
{
    "variants": [{
        "attributes": [
            {"key": "color", "value": "مشکی", "isDistinctive": true},
            {"key": "size", "value": "M", "isDistinctive": false}
        ]
    }]
}
```

## Benefits

1. ✅ **Cleaner API**: Removed redundant variant-level `isDistinctive`
2. ✅ **Better UX**: Clear UI to select which attribute is distinctive
3. ✅ **Automatic Selection**: If only one attribute, auto-mark as distinctive
4. ✅ **Data Integrity**: Only ONE attribute can be distinctive (radio button enforced)
5. ✅ **Mobile-Friendly**: Swift/mobile apps can now properly highlight the main differentiating attribute

## Future Enhancements

- Add validation to ensure distinctive attribute is always selected when variants exist
- Add UI indicator showing which attribute is distinctive in the variant list
- Allow editing distinctive attribute for existing products

