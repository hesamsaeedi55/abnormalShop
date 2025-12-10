// MARK: - Fixed preloadAllSubcategories Function
// Option 1: Flatten all categories first (RECOMMENDED)

private func preloadAllSubcategories() async {
    // ✅ Flatten all categories from both men and women
    let allParentCategories = catVM.genderCategories.values.flatMap { $0 }
    
    // ✅ Load subcategories for all parent categories in parallel
    await withTaskGroup(of: Void.self) { group in
        for category in allParentCategories {
            group.addTask {
                await catVM.loadSubCategories(category.id)
            }
        }
    }
}

// MARK: - Option 2: Iterate through each gender's categories

private func preloadAllSubcategoriesByGender() async {
    await withTaskGroup(of: Void.self) { group in
        // Iterate through each gender (men, women)
        for (gender, categories) in catVM.genderCategories {
            // Iterate through each category in this gender
            for category in categories {
                group.addTask {
                    await catVM.loadSubCategories(category.id)
                }
            }
        }
    }
}

// MARK: - Option 3: Only preload for current gender (if you want to be selective)

private func preloadSubcategoriesForCurrentGender() async {
    let currentGender = catVM.isMenTapped! ? "men" : "women"
    
    guard let categories = catVM.genderCategories[currentGender] else {
        return
    }
    
    await withTaskGroup(of: Void.self) { group in
        for category in categories {
            group.addTask {
                await catVM.loadSubCategories(category.id)
            }
        }
    }
}

// MARK: - Option 4: Preload for both genders separately (with logging)

private func preloadAllSubcategoriesWithLogging() async {
    let allParentCategories = catVM.genderCategories.values.flatMap { $0 }
    
    print("🔄 Starting to preload subcategories for \(allParentCategories.count) parent categories...")
    
    await withTaskGroup(of: Void.self) { group in
        for category in allParentCategories {
            group.addTask {
                print("⏳ Loading subcategories for: \(category.label) (ID: \(category.id))")
                await catVM.loadSubCategories(category.id)
                print("✅ Completed loading subcategories for: \(category.label)")
            }
        }
    }
    
    print("✅ Finished preloading all subcategories")
}


