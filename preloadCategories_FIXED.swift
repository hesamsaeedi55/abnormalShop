// MARK: - Preload Categories Function
// Add this function to your CategoryViewModel

func preloadAllCategories() async {
    guard !isLoading else {
        return
    }
    
    // ✅ Set Parent to true for loading parent categories
    Parent = true
    
    // ✅ Load both men and women categories in parallel
    await withTaskGroup(of: Void.self) { group in
        // Load men's categories
        group.addTask { [weak self] in
            guard let self = self else { return }
            let originalValue = self.isMenTapped
            await MainActor.run {
                self.isMenTapped = true
            }
            await self.loadCategories()
            await MainActor.run {
                self.isMenTapped = originalValue // Restore original value
            }
        }
        
        // Load women's categories
        group.addTask { [weak self] in
            guard let self = self else { return }
            let originalValue = self.isMenTapped
            await MainActor.run {
                self.isMenTapped = false
            }
            await self.loadCategories()
            await MainActor.run {
                self.isMenTapped = originalValue // Restore original value
            }
        }
    }
}

// MARK: - Alternative: Simpler version if you don't need to preserve isMenTapped
func preloadAllCategoriesSimple() async {
    guard !isLoading else {
        return
    }
    
    Parent = true
    
    // Load men's categories
    await MainActor.run {
        isMenTapped = true
    }
    await loadCategories()
    
    // Load women's categories
    await MainActor.run {
        isMenTapped = false
    }
    await loadCategories()
    
    // Restore to default (or keep the last loaded one)
    await MainActor.run {
        isMenTapped = true // or false, depending on your default
    }
}

// MARK: - Even Better: Create separate functions that don't depend on isMenTapped
func loadMenCategories() async {
    guard !isLoading else {
        return
    }
    
    await MainActor.run {
        isLoading = true
        Parent = true
    }
    
    let urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parents/by-gender/?gender_name=men"
    
    guard let url = URL(string: urlString) else {
        await MainActor.run {
            isLoading = false
        }
        return
    }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let response = try decoder.decode(parentCategoryModel.self, from: data)
        
        await MainActor.run {
            self.genderCategories["men"] = response.categories
            self.isLoading = false
            print("✅ Men's categories preloaded: \(response.categories.count) items")
        }
    } catch {
        print("❌ Error loading men's categories: \(error)")
        await MainActor.run {
            isLoading = false
        }
    }
}

func loadWomenCategories() async {
    guard !isLoading else {
        return
    }
    
    await MainActor.run {
        isLoading = true
        Parent = true
    }
    
    let urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parents/by-gender/?gender_name=women"
    
    guard let url = URL(string: urlString) else {
        await MainActor.run {
            isLoading = false
        }
        return
    }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let response = try decoder.decode(parentCategoryModel.self, from: data)
        
        await MainActor.run {
            self.genderCategories["women"] = response.categories
            self.isLoading = false
            print("✅ Women's categories preloaded: \(response.categories.count) items")
        }
    } catch {
        print("❌ Error loading women's categories: \(error)")
        await MainActor.run {
            isLoading = false
        }
    }
}

// ✅ BEST SOLUTION: Preload both in parallel without affecting isMenTapped
func preloadAllCategoriesBest() async {
    // ✅ Load both in parallel without changing isMenTapped
    await withTaskGroup(of: Void.self) { group in
        group.addTask { [weak self] in
            await self?.loadMenCategories()
        }
        
        group.addTask { [weak self] in
            await self?.loadWomenCategories()
        }
    }
}


