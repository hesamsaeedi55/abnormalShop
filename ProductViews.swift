//
//  ProductViews.swift
//  Customer E-commerce iOS App
//
//  Product browsing, search, and detail views for the customer platform
//

import SwiftUI
import Combine

// MARK: - Home View
struct HomeView: View {
    @StateObject private var productManager = ProductManager()
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var wishlistManager: WishlistManager
    @State private var searchText = ""
    @State private var showingSearch = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Search Bar
                    SearchBar(text: $searchText, onSearchButtonClicked: {
                        showingSearch = true
                    })
                    .padding(.horizontal)
                    
                    // Featured Products
                    if !productManager.featuredProducts.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Featured Products")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button("See All") {
                                    // Navigate to all products
                                }
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(productManager.featuredProducts) { product in
                                        ProductCard(product: product)
                                            .frame(width: 160)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Categories
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Categories")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(productManager.categories) { category in
                                CategoryCard(category: category)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // New Arrivals
                    if !productManager.newArrivals.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("New Arrivals")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button("See All") {
                                    // Navigate to new arrivals
                                }
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(productManager.newArrivals) { product in
                                        ProductCard(product: product)
                                            .frame(width: 160)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .refreshable {
                await productManager.loadHomeData()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView(searchText: searchText)
            }
            .onAppear {
                Task {
                    await productManager.loadHomeData()
                }
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search products...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var wishlistManager: WishlistManager
    @State private var showingProductDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: product.images.first?.image ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
                
                // Wishlist Button
                Button(action: {
                    if wishlistManager.isInWishlist(productId: product.id) {
                        wishlistManager.removeFromWishlist(productId: product.id)
                    } else {
                        wishlistManager.addToWishlist(productId: product.id)
                    }
                }) {
                    Image(systemName: wishlistManager.isInWishlist(productId: product.id) ? "heart.fill" : "heart")
                        .foregroundColor(wishlistManager.isInWishlist(productId: product.id) ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text("\(product.priceToman) تومان")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let priceUsd = product.priceUsd {
                        Text("($\(String(format: "%.2f", priceUsd)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Rating
                if let rating = product.averageRating, rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        
                        Text("(\(product.reviewCount))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Add to Cart Button
            Button(action: {
                cartManager.addToCart(productId: product.id)
            }) {
                Text("Add to Cart")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .onTapGesture {
            showingProductDetail = true
        }
        .sheet(isPresented: $showingProductDetail) {
            ProductDetailView(product: product)
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: Category
    @State private var showingCategoryProducts = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Category Icon
            Circle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: category.icon ?? "folder")
                        .font(.title2)
                        .foregroundColor(.primary)
                )
            
            // Category Name
            Text(category.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            showingCategoryProducts = true
        }
        .sheet(isPresented: $showingCategoryProducts) {
            CategoryProductsView(category: category)
        }
    }
}

// MARK: - Search View
struct SearchView: View {
    let searchText: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchManager = SearchManager()
    @State private var searchQuery = ""
    @State private var selectedCategory: Int?
    @State private var priceRange: ClosedRange<Double> = 0...1000000
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                HStack {
                    SearchBar(text: $searchQuery) {
                        performSearch()
                    }
                    
                    Button("Filter") {
                        showingFilters = true
                    }
                    .foregroundColor(.primary)
                }
                .padding()
                
                // Search Results
                if searchManager.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if searchManager.searchResults.isEmpty && !searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No products found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Try adjusting your search terms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(searchManager.searchResults) { product in
                                ProductCard(product: product)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(
                    selectedCategory: $selectedCategory,
                    priceRange: $priceRange,
                    onApplyFilters: {
                        performSearch()
                        showingFilters = false
                    }
                )
            }
            .onAppear {
                searchQuery = searchText
                if !searchText.isEmpty {
                    performSearch()
                }
            }
        }
    }
    
    private func performSearch() {
        Task {
            await searchManager.searchProducts(
                query: searchQuery,
                categoryId: selectedCategory,
                minPrice: Int(priceRange.lowerBound),
                maxPrice: Int(priceRange.upperBound)
            )
        }
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: Int?
    @Binding var priceRange: ClosedRange<Double>
    let onApplyFilters: () -> Void
    
    @StateObject private var categoryManager = CategoryManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as Int?)
                        ForEach(categoryManager.categories) { category in
                            Text(category.name).tag(category.id as Int?)
                        }
                    }
                }
                
                Section("Price Range") {
                    VStack(alignment: .leading) {
                        Text("Price Range: \(Int(priceRange.lowerBound)) - \(Int(priceRange.upperBound)) تومان")
                            .font(.subheadline)
                        
                        RangeSlider(
                            range: $priceRange,
                            bounds: 0...1000000,
                            step: 10000
                        )
                    }
                }
                
                Section {
                    Button("Apply Filters") {
                        onApplyFilters()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selectedCategory = nil
                        priceRange = 0...1000000
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await categoryManager.loadCategories()
                }
            }
        }
    }
}

// MARK: - Range Slider
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Active range
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 4)
                    .cornerRadius(2)
                    .offset(x: CGFloat((range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                    .frame(width: CGFloat((range.upperBound - range.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width)
                
                // Lower thumb
                Circle()
                    .fill(Color.primary)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat((range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = bounds.lowerBound + (value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                let steppedValue = round(newValue / step) * step
                                let clampedValue = max(bounds.lowerBound, min(steppedValue, range.upperBound - step))
                                range = clampedValue...range.upperBound
                            }
                    )
                
                // Upper thumb
                Circle()
                    .fill(Color.primary)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat((range.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)) * geometry.size.width - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = bounds.lowerBound + (value.location.x / geometry.size.width) * (bounds.upperBound - bounds.lowerBound)
                                let steppedValue = round(newValue / step) * step
                                let clampedValue = max(range.lowerBound + step, min(steppedValue, bounds.upperBound))
                                range = range.lowerBound...clampedValue
                            }
                    )
            }
        }
        .frame(height: 20)
    }
}

// MARK: - Category View
struct CategoryView: View {
    @StateObject private var categoryManager = CategoryManager()
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading categories...")
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(categoryManager.categories) { category in
                                CategoryCard(category: category)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Categories")
            .refreshable {
                await loadCategories()
            }
            .onAppear {
                Task {
                    await loadCategories()
                }
            }
        }
    }
    
    private func loadCategories() async {
        await categoryManager.loadCategories()
        isLoading = false
    }
}

// MARK: - Category Products View
struct CategoryProductsView: View {
    let category: Category
    @Environment(\.dismiss) private var dismiss
    @StateObject private var productManager = ProductManager()
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading products...")
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(productManager.products) { product in
                                ProductCard(product: product)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await productManager.loadProductsByCategory(categoryId: category.id)
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Product Detail View
struct ProductDetailView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var wishlistManager: WishlistManager
    @State private var selectedVariant: ProductVariant?
    @State private var quantity = 1
    @State private var showingImageFullscreen = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Images
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(product.images.enumerated()), id: \.offset) { index, image in
                            AsyncImage(url: URL(string: image.image)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.secondary)
                                    )
                            }
                            .tag(index)
                            .onTapGesture {
                                showingImageFullscreen = true
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    
                    // Product Info
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(product.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                if wishlistManager.isInWishlist(productId: product.id) {
                                    wishlistManager.removeFromWishlist(productId: product.id)
                                } else {
                                    wishlistManager.addToWishlist(productId: product.id)
                                }
                            }) {
                                Image(systemName: wishlistManager.isInWishlist(productId: product.id) ? "heart.fill" : "heart")
                                    .foregroundColor(wishlistManager.isInWishlist(productId: product.id) ? .red : .primary)
                                    .font(.title2)
                            }
                        }
                        
                        // Price
                        HStack {
                            Text("\(product.priceToman) تومان")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if let priceUsd = product.priceUsd {
                                Text("($\(String(format: "%.2f", priceUsd)))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Rating
                        if let rating = product.averageRating, rating > 0 {
                            HStack(spacing: 5) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                                
                                Text("(\(product.reviewCount) reviews)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Description
                        if !product.description.isEmpty {
                            Text("Description")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(product.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Variants
                        if !product.variants.isEmpty {
                            Text("Options")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(product.variants) { variant in
                                    VariantButton(
                                        variant: variant,
                                        isSelected: selectedVariant?.id == variant.id,
                                        onTap: { selectedVariant = variant }
                                    )
                                }
                            }
                        }
                        
                        // Quantity Selector
                        HStack {
                            Text("Quantity")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    if quantity > 1 {
                                        quantity -= 1
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                }
                                .disabled(quantity <= 1)
                                
                                Text("\(quantity)")
                                    .font(.headline)
                                    .frame(minWidth: 30)
                                
                                Button(action: {
                                    quantity += 1
                                }) {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Add to Cart Button
                Button(action: addToCart) {
                    HStack {
                        Text("Add to Cart")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(getTotalPrice()) تومان")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .fullScreenCover(isPresented: $showingImageFullscreen) {
                ImageFullscreenView(
                    images: product.images,
                    selectedIndex: $selectedImageIndex
                )
            }
        }
    }
    
    private func addToCart() {
        cartManager.addToCart(
            productId: product.id,
            variantId: selectedVariant?.id,
            quantity: quantity
        )
        dismiss()
    }
    
    private func getTotalPrice() -> Int {
        let unitPrice = selectedVariant?.priceToman ?? product.priceToman
        return unitPrice * quantity
    }
}

// MARK: - Variant Button
struct VariantButton: View {
    let variant: ProductVariant
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Text(variant.variantName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(variant.priceToman) تومان")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if variant.stockQuantity <= 0 {
                    Text("Out of Stock")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.primary : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .disabled(variant.stockQuantity <= 0)
    }
}

// MARK: - Image Fullscreen View
struct ImageFullscreenView: View {
    let images: [ProductImage]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    AsyncImage(url: URL(string: image.image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            )
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Data Managers
class ProductManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var featuredProducts: [Product] = []
    @Published var newArrivals: [Product] = []
    @Published var isLoading = false
    
    private let apiManager = APIManager.shared
    
    func loadHomeData() async {
        await loadFeaturedProducts()
        await loadNewArrivals()
    }
    
    func loadFeaturedProducts() async {
        // Load featured products from API
        // Implementation depends on your API
    }
    
    func loadNewArrivals() async {
        // Load new arrivals from API
        // Implementation depends on your API
    }
    
    func loadProductsByCategory(categoryId: Int) async {
        isLoading = true
        
        do {
            let url = URL(string: "\(apiManager.baseURL)/products/?category=\(categoryId)")!
            let request = apiManager.createRequest(url: url)
            
            let response: [Product] = try await apiManager.performRequest(request, responseType: [Product].self)
            
            await MainActor.run {
                self.products = response
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

class SearchManager: ObservableObject {
    @Published var searchResults: [Product] = []
    @Published var isLoading = false
    
    private let apiManager = APIManager.shared
    
    func searchProducts(query: String, categoryId: Int? = nil, minPrice: Int? = nil, maxPrice: Int? = nil) async {
        isLoading = true
        
        do {
            var urlComponents = URLComponents(string: "\(apiManager.baseURL)/products/")!
            var queryItems: [URLQueryItem] = []
            
            if !query.isEmpty {
                queryItems.append(URLQueryItem(name: "search", value: query))
            }
            if let categoryId = categoryId {
                queryItems.append(URLQueryItem(name: "category", value: String(categoryId)))
            }
            if let minPrice = minPrice {
                queryItems.append(URLQueryItem(name: "min_price", value: String(minPrice)))
            }
            if let maxPrice = maxPrice {
                queryItems.append(URLQueryItem(name: "max_price", value: String(maxPrice)))
            }
            
            urlComponents.queryItems = queryItems
            
            let request = apiManager.createRequest(url: urlComponents.url!)
            let response: [Product] = try await apiManager.performRequest(request, responseType: [Product].self)
            
            await MainActor.run {
                self.searchResults = response
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

class CategoryManager: ObservableObject {
    @Published var categories: [Category] = []
    
    private let apiManager = APIManager.shared
    
    func loadCategories() async {
        do {
            let url = URL(string: "\(apiManager.baseURL)/categories/")!
            let request = apiManager.createRequest(url: url)
            
            let response: [Category] = try await apiManager.performRequest(request, responseType: [Category].self)
            
            await MainActor.run {
                self.categories = response
            }
        } catch {
            // Handle error
        }
    }
}

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let icon: String?
    let description: String?
}
