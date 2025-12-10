// MARK: - Fixed loadCategories() Function
// Replace your existing loadCategories() function with this version

func loadCategories() async {
    guard !isLoading else {
        return
    }
    
    await MainActor.run {
        isLoading = true
    }
    
    var urlString : String = ""
    
    if Parent == true {
        // Loading parent categories
        do {
            if isMenTapped! {
                urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parents/by-gender/?gender_name=men"
            } else {
                urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parents/by-gender/?gender_name=women"
            }
            
            print("🌐 URL for parent categories: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                print("❌ Failed to create URL from string: \(urlString)")
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            print("✅ URL created successfully, making network request...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Network request completed, decoding data...")
            
            let decoder = JSONDecoder()
            let response = try decoder.decode(parentCategoryModel.self, from: data)
            print("✅ Data decoded successfully: \(response.categories)")
            
            await MainActor.run {
                self.parentCategories = response.categories
                self.isLoading = false
                print("✅ Parent categories loaded and isLoading set to false")
            }
                    
        } catch {
            print("❌ Error loading parent categories: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
            
    } else {
        // Loading subcategories for a specific parent
        print("📁 Loading sub categories...")
        
        do {
            guard let parentId = selectedCategory?.id else {
                print("❌ No selectedCategory or selectedCategory.id is nil")
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            print("Parent ID: \(parentId)")
            
            // ✅ FIX: Use proper string value for gender_name parameter
            let genderName = isMenTapped! ? "men" : "women"
            urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parent/\(parentId)/children/by-gender/?gender_name=\(genderName)"
            
            // Alternative endpoint (if you prefer flattened):
            // urlString = "https://myshop-backend-an7h.onrender.com/shop/api/categories/parent/\(parentId)/flattened-by-gender/?gender_name=\(genderName)"
            
            print("🌐 URL for sub categories: \(urlString)")

            guard let url = URL(string: urlString) else {
                print("❌ Failed to create URL from string: \(urlString)")
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            print("✅ URL created successfully, making network request...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Network request completed, decoding data...")
            
            let decoder = JSONDecoder()
            let response = try decoder.decode(subCategoryModel.self, from: data)
            print("✅ Data decoded successfully: \(response.categories)")
            
            await MainActor.run {
                // ✅ FIX: Store subcategories in dictionary by parent ID
                // OLD (WRONG): self.subCategoriesByParent = response.categories
                // NEW (CORRECT): Store by parent ID key
                self.subCategoriesByParent[parentId] = response.categories
                self.isLoading = false
                print("✅ Sub categories loaded for parent \(parentId): \(response.categories.count) items")
            }
                    
        } catch {
            print("❌ Error loading sub categories: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}


