// MARK: - Fix for Shimmer2 Button - Wait for products to load before navigating

// In your Shimmer2 component, replace the Button action with this:

Button {
    Task {
        // ✅ Show loading state
        await MainActor.run {
            sortVM.isLoading = true
        }
        
        // ✅ Load categories first
        await CVM.loadCategories()
        
        // ✅ Set up all the view models
        AVM.categoryID = cat.id
        sortVM.categoryId = cat.id
        
        await AVM.loadValueCategories()
        
        CVM.selectedCatID = cat.id
        PVM.categoryId = cat.id
        
        AVM.selectedValue = AVM.selectedKeyAsValue?.values.first
        
        CVM.selectedCatNAME = cat.label
        
        // ✅ IMPORTANT: Load products BEFORE navigating
        // This ensures products are ready when FeedView appears
        await sortVM.sortProduct(categoryID: cat.id, filters: [:])
        
        // ✅ Wait until products are loaded (not loading anymore)
        // This prevents navigating to an empty FeedView
        while sortVM.isLoading {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // ✅ Only navigate after products are loaded
        await MainActor.run {
            // Navigate to FeedView using NavigationStackManager
            let feedView = FeedView(isMainTabBarPresented: .constant(true))
                .environmentObject(cateogryviewmodel)
                .environmentObject(PVM)
                .environmentObject(AVM)
                .environmentObject(sortVM)
                .environmentObject(specialOfferViewModel())
                .environmentObject(navigationManager)
            
            navigationManager.pushView(feedView, to: .review)
        }
    }
} label: {
    VStack {
        Spacer()
        Text(cat.label)
            .font(.custom("DoranNoEn-Medium", size: 18))
            .padding(.horizontal, 10)
            .foregroundStyle(CVM.selectedCatID == cat.id ? .red : Color.gray)
        Spacer()
    }
}

// MARK: - Alternative: Better approach with loading indicator

// If you want to show a loading indicator while products load:

@State private var isNavigating: Bool = false

Button {
    Task {
        isNavigating = true
        
        await CVM.loadCategories()
        
        AVM.categoryID = cat.id
        sortVM.categoryId = cat.id
        
        await AVM.loadValueCategories()
        
        CVM.selectedCatID = cat.id
        PVM.categoryId = cat.id
        
        AVM.selectedValue = AVM.selectedKeyAsValue?.values.first
        CVM.selectedCatNAME = cat.label
        
        // Load products
        await sortVM.sortProduct(categoryID: cat.id, filters: [:])
        
        // Wait for loading to complete
        while sortVM.isLoading {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Ensure we have products before navigating
        guard !sortVM.sortedProducts.isEmpty else {
            print("⚠️ No products loaded, not navigating")
            isNavigating = false
            return
        }
        
        await MainActor.run {
            let feedView = FeedView(isMainTabBarPresented: .constant(true))
                .environmentObject(cateogryviewmodel)
                .environmentObject(PVM)
                .environmentObject(AVM)
                .environmentObject(sortVM)
                .environmentObject(specialOfferViewModel())
                .environmentObject(navigationManager)
            
            navigationManager.pushView(feedView, to: .review)
            isNavigating = false
        }
    }
} label: {
    HStack {
        if isNavigating {
            ProgressView()
                .scaleEffect(0.8)
                .padding(.trailing, 5)
        }
        Text(cat.label)
            .font(.custom("DoranNoEn-Medium", size: 18))
            .padding(.horizontal, 10)
            .foregroundStyle(CVM.selectedCatID == cat.id ? .red : Color.gray)
    }
}


