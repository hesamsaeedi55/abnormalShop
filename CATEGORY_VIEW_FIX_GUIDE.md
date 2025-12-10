# CategoryView Subcategories Preloading Fix

## Problem
When preloading subcategories for multiple parent categories, they were overwriting each other because `subCategories` was a single array. Each time you loaded subcategories for a new parent, it replaced the previous ones.

## Solution
Change `subCategories` from a single array to a dictionary keyed by parent category ID.

## Required Changes to CategoryViewModel

### Step 1: Update the Property Declaration

**FIND THIS IN YOUR CategoryViewModel:**
```swift
@Published var subCategories: [SubCategory] = []
```

**REPLACE WITH:**
```swift
@Published var subCategoriesByParent: [Int: [SubCategory]] = [:]
```

### Step 2: Update the loadSubCategories Extension

**FIND THIS IN YOUR CategoryViewModel EXTENSION:**
```swift
extension CategoryViewModel {
    func loadSubCategories(_ parentId: Int) async {
        // ... existing code ...
        await MainActor.run {
            subCategories = decoded.categories  // ❌ OLD - overwrites previous
            print(subCategories)
        }
    }
}
```

**REPLACE WITH:**
```swift
extension CategoryViewModel {
    func loadSubCategories(_ parentId: Int) async {
        var urlString: String
        
        if isMenTapped! {
             urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parent/\(parentId)/flattened-by-gender/?gender_name=men"
        } else {
             urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parent/\(parentId)/flattened-by-gender/?gender_name=women"
        }
        
        var request = URLRequest(url : URL(string:urlString)!)
        request.setValue( "application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        do {
            let (data,_) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(subCategoryModel.self, from: data)
            
            await MainActor.run {
                // ✅ Store by parent ID - no overwriting
                subCategoriesByParent[parentId] = decoded.categories
                print("✅ Loaded \(decoded.categories.count) subcategories for parent \(parentId)")
            }
        } catch {
            print("❌ Error loading subcategories for parent \(parentId): \(error)")
        }
    }
    
    // ✅ Add this helper method
    func getSubCategories(for parentId: Int) -> [SubCategory] {
        return subCategoriesByParent[parentId] ?? []
    }
}
```

### Step 3: Fix the loadCategories() Function

**FIND THIS IN YOUR loadCategories() FUNCTION (in the `else` branch):**
```swift
urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parent/\(parentId)/children/by-gender/?gender_name=\(isMenTapped)"

// ... later in the code ...

await MainActor.run {
    self.subCategoriesByParent = response.categories  // ❌ WRONG - trying to assign array to dictionary
    self.isLoading = false
}
```

**REPLACE WITH:**
```swift
// ✅ FIX: Use proper string value for gender_name parameter
let genderName = isMenTapped! ? "men" : "women"
urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parent/\(parentId)/children/by-gender/?gender_name=\(genderName)"

// ... later in the code ...

await MainActor.run {
    // ✅ FIX: Store subcategories in dictionary by parent ID
    self.subCategoriesByParent[parentId] = response.categories
    self.isLoading = false
    print("✅ Sub categories loaded for parent \(parentId): \(response.categories.count) items")
}
```

**See `loadCategories_FIXED.swift` for the complete corrected function.**

### Step 4: Update Any Code That Accesses subCategories

**FIND ALL INSTANCES OF:**
```swift
CVM.subCategories
cateogryviewmodel.subCategories
```

**REPLACE WITH:**
```swift
CVM.getSubCategories(for: parentId)
cateogryviewmodel.getSubCategories(for: parentId)
```

## Updated CategoryView

The `CategoryView_FIXED.swift` file includes:
1. ✅ Automatic preloading of all subcategories when parent categories load
2. ✅ Preloading when gender changes
3. ✅ Parallel loading for better performance
4. ✅ Updated Shimmer2 to use the dictionary-based approach

## Key Changes in CategoryView

1. **Added preloading trigger:**
```swift
.onChange(of: catVM.parentCategories) { _ in
    if !hasPreloadedSubcategories && !catVM.parentCategories.isEmpty {
        Task {
            await preloadAllSubcategories()
            hasPreloadedSubcategories = true
        }
    }
}
```

2. **Added preload function:**
```swift
private func preloadAllSubcategories() async {
    await withTaskGroup(of: Void.self) { group in
        for category in catVM.parentCategories {
            group.addTask {
                await catVM.loadSubCategories(category.id)
            }
        }
    }
}
```

3. **Updated Shimmer2 to use dictionary:**
```swift
private var subCategoriesForParent: [SubCategory] {
    CVM.getSubCategories(for: subcat.id)
}
```

## Testing

1. Navigate to CategoryView
2. Wait for parent categories to load
3. Subcategories should preload automatically in the background
4. Tap on any parent category - subcategories should appear instantly (no loading delay)
5. Switch between men/women tabs - subcategories should reload for the new gender

## Benefits

- ✅ No more overwriting - each parent's subcategories are stored separately
- ✅ Instant display - subcategories are preloaded, so tapping shows them immediately
- ✅ Better performance - parallel loading of all subcategories
- ✅ Cleaner code - dictionary-based approach is more maintainable

