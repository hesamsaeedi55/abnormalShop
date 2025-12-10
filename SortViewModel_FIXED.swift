//
//  SortViewModel.swift
//  ssssss
//
//  Created by Hesamoddin Saeedi on 8/24/25.
//

import Foundation

struct sortModel {
    let sortby: String
    let sortorder: String
    
    init(sortby: String, sortorder: String) {
        self.sortby = sortby
        self.sortorder = sortorder
    }
}

class SortViewModel: ObservableObject {
   
    @Published var sortedProducts: [ProductTest] = []
    @Published var isLoading: Bool = false
    @Published var page : Int = 1
    @Published var perPage : Int = 10
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @Published var sortCaseSelection: sortMode = .TimeOldest
    @Published var sortPublishModel: sortModel = sortModel(sortby: "created_at", sortorder: "desc")
    @Published var categoryId: Int = 1036
    @Published var isSelectingAttributeCategory: Bool = false
    @Published var selectedKeyValue: [String:[String]] = [:]
    @Published var activeFilters: [String:[String]] = [:]
    @Published var isFilterActive: Bool = false
    @Published var specialOffersProducts : [specialOffersProducts] = []
    @Published var isInAllProductsTab: Bool = false
    @Published var lastError: String? = nil // Add error tracking
    
    // Filter management methods
    func addFilter(key: String, value: String) {
        if var currentValues = activeFilters[key] {
            if !currentValues.contains(value) {
                currentValues.append(value)
                activeFilters[key] = currentValues
            }
        } else {
            activeFilters[key] = [value]
        }
        isFilterActive = !activeFilters.isEmpty
    }
    
    func removeFilter(key: String, value: String) {
        if var currentValues = activeFilters[key] {
            currentValues.removeAll { $0 == value }
            if currentValues.isEmpty {
                activeFilters.removeValue(forKey: key)
            } else {
                activeFilters[key] = currentValues
            }
        }
        isFilterActive = !activeFilters.isEmpty
    }
    
    func toggleFilter(key: String, value: String) {
        if let currentValues = activeFilters[key], currentValues.contains(value) {
            removeFilter(key: key, value: value)
        } else {
            addFilter(key: key, value: value)
        }
    }
    
    func clearAllFilters() {
        activeFilters.removeAll()
        isFilterActive = false
    }
    
    func clearFiltersForKey(key: String) {
        activeFilters.removeValue(forKey: key)
        isFilterActive = !activeFilters.isEmpty
    }
    
    enum sortMode {
        case TimeNewest
        case TimeOldest
        case priceAscending
        case priceDescending
    }
    
    func SortModeSelection(_ sortMode: sortMode) -> sortModel {
        switch sortMode {
        case .TimeNewest:
            return sortModel(sortby: "created_at", sortorder: "desc")
        case .TimeOldest:
            return sortModel(sortby: "created_at", sortorder: "asc")
        case .priceAscending:
            return sortModel(sortby: "price_toman", sortorder: "asc")
        case .priceDescending:
            return sortModel(sortby: "price_toman", sortorder: "desc")
        }
    }
    
    // FIXED: Completely rewritten sortProduct function with comprehensive error handling
    func sortProduct(categoryID: Int, filters: [String:[String]]) async {
        print("🔄 [SortViewModel] sortProduct called")
        print("🔄 Category ID: \(categoryID)")
        print("🔄 Current Page: \(currentPage)")
        print("🔄 Filters: \(filters)")
        print("🔄 Is Loading: \(isLoading)")
        print("🔄 Has More Pages: \(hasMorePages)")
        
        // FIX: Check loading state properly
        guard !isLoading else {
            print("⚠️ [SortViewModel] Already loading, skipping request")
            return
        }
        
        guard hasMorePages || currentPage == 1 else {
            print("⚠️ [SortViewModel] No more pages and not first page, skipping")
            return
        }
        
        // FIX: Set loading state on main thread
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
            self.page = self.currentPage
            self.perPage = self.perPage
            
            if self.currentPage == 1 {
                self.sortedProducts = []
                print("🔄 [SortViewModel] Cleared products for page 1")
            }
        }
        
        // FIX: Build URL with proper error handling
        var urlComponents: URLComponents
        do {
            urlComponents = try buildURLComponents(categoryID: categoryID, filters: filters)
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.lastError = "خطا در ساخت آدرس: \(error.localizedDescription)"
            }
            print("❌ [SortViewModel] URL construction error: \(error)")
            return
        }
        
        guard let url = urlComponents.url else {
            await MainActor.run {
                self.isLoading = false
                self.lastError = "آدرس نامعتبر"
            }
            print("❌ [SortViewModel] Invalid URL: \(urlComponents)")
            return
        }
        
        print("🌐 [SortViewModel] Request URL: \(url.absoluteString)")
        
        // FIX: Create request with timeout
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // 30 second timeout
        
        // FIX: Perform request with comprehensive error handling
        do {
            print("📡 [SortViewModel] Starting network request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // FIX: Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "SortViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            }
            
            print("📡 [SortViewModel] HTTP Status: \(httpResponse.statusCode)")
            
            // FIX: Check status code
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                print("❌ [SortViewModel] HTTP Error \(httpResponse.statusCode): \(errorBody)")
                throw NSError(
                    domain: "SortViewModel",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"]
                )
            }
            
            // FIX: Check if data is empty
            guard !data.isEmpty else {
                print("⚠️ [SortViewModel] Empty response data")
                await MainActor.run {
                    if self.currentPage == 1 {
                        self.sortedProducts = []
                    }
                    self.hasMorePages = false
                    self.isLoading = false
                }
                return
            }
            
            print("📦 [SortViewModel] Response data size: \(data.count) bytes")
            
            // FIX: Decode with error handling
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let decoded: ProductResponse
            do {
                decoded = try decoder.decode(ProductResponse.self, from: data)
                print("✅ [SortViewModel] Successfully decoded response")
                print("📊 [SortViewModel] Products count: \(decoded.products.count)")
                print("📊 [SortViewModel] Has next page: \(decoded.pagination.hasNext)")
            } catch {
                print("❌ [SortViewModel] Decoding error: \(error)")
                print("❌ [SortViewModel] Error details: \(error.localizedDescription)")
                
                // Try to print the raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 [SortViewModel] Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
                }
                
                await MainActor.run {
                    self.isLoading = false
                    self.lastError = "خطا در خواندن پاسخ: \(error.localizedDescription)"
                }
                return
            }
            
            // FIX: Update state on main thread
            await MainActor.run {
                if self.currentPage == 1 {
                    self.sortedProducts = decoded.products
                    print("✅ [SortViewModel] Set products for page 1: \(decoded.products.count) items")
                } else {
                    self.sortedProducts.append(contentsOf: decoded.products)
                    print("✅ [SortViewModel] Appended products for page \(self.currentPage): \(decoded.products.count) items")
                }
                
                self.hasMorePages = decoded.pagination.hasNext
                self.currentPage += 1
                self.isLoading = false
                
                print("✅ [SortViewModel] Total products now: \(self.sortedProducts.count)")
                print("✅ [SortViewModel] Has more pages: \(self.hasMorePages)")
                print("✅ [SortViewModel] Next page will be: \(self.currentPage)")
            }
            
        } catch let error as URLError {
            // FIX: Handle specific URL errors
            print("❌ [SortViewModel] URL Error: \(error.localizedDescription)")
            print("❌ [SortViewModel] Error code: \(error.code.rawValue)")
            
            let errorMessage: String
            switch error.code {
            case .timedOut:
                errorMessage = "زمان اتصال به سرور به پایان رسید"
            case .notConnectedToInternet:
                errorMessage = "اتصال به اینترنت برقرار نیست"
            case .cannotFindHost:
                errorMessage = "سرور یافت نشد"
            case .cannotConnectToHost:
                errorMessage = "امکان اتصال به سرور وجود ندارد"
            default:
                errorMessage = "خطای شبکه: \(error.localizedDescription)"
            }
            
            await MainActor.run {
                self.isLoading = false
                self.lastError = errorMessage
            }
            
        } catch {
            // FIX: Handle other errors
            print("❌ [SortViewModel] Unknown error: \(error)")
            print("❌ [SortViewModel] Error type: \(type(of: error))")
            print("❌ [SortViewModel] Error description: \(error.localizedDescription)")
            
            await MainActor.run {
                self.isLoading = false
                self.lastError = "خطای ناشناخته: \(error.localizedDescription)"
            }
        }
    }
    
    // FIX: Extract URL building to separate function for better error handling
    private func buildURLComponents(categoryID: Int, filters: [String:[String]]) throws -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "myshop-backend-an7h.onrender.com"
        components.path = "/shop/api/category/\(categoryID)/filter"
        
        var queryItems = [
            URLQueryItem(name: "sort_by", value: sortPublishModel.sortby),
            URLQueryItem(name: "sort_order", value: sortPublishModel.sortorder),
            URLQueryItem(name: "page", value: String(currentPage)),
            URLQueryItem(name: "per_page", value: String(perPage)),
        ]
        
        // FIX: Handle filters properly
        if isSelectingAttributeCategory {
            for (attribute_key, values) in filters {
                if let lastValue = values.last {
                    queryItems.append(URLQueryItem(name: attribute_key, value: lastValue))
                }
            }
        } else {
            if !filters.isEmpty && !isInAllProductsTab {
                for (key, values) in filters {
                    for value in values {
                        queryItems.append(URLQueryItem(name: key, value: value))
                    }
                }
            }
        }
        
        components.queryItems = queryItems
        return components
    }
    
    // FIXED: loadSpecialOffersProducts with same improvements
    func loadSpecialOffersProducts(offerId: Int, selectedCategory: Int?, man: Bool, filters: [String:[String]]) async {
        print("🔄 [SortViewModel] loadSpecialOffersProducts called")
        print("🔄 Offer ID: \(offerId)")
        print("🔄 Selected Category: \(selectedCategory ?? -1)")
        print("🔄 Gender: \(man ? "men" : "women")")
        
        guard !isLoading && (hasMorePages || currentPage == 1) else {
            print("⚠️ [SortViewModel] Already loading or no more pages")
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.lastError = nil
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "myshop-backend-an7h.onrender.com"
        components.port = 80
        components.path = "/shop/api/special-offers/\(offerId)/"
        
        var queryItems = [
            URLQueryItem(name: "gender", value: man ? "men" : "women"),
            URLQueryItem(name: "category_id", value: selectedCategory == -1 ? nil : "\(selectedCategory!)"),
            URLQueryItem(name: "sort_by", value: sortPublishModel.sortby),
            URLQueryItem(name: "sort_order", value: sortPublishModel.sortorder),
            URLQueryItem(name: "page", value: String(currentPage)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        
        if isSelectingAttributeCategory {
            for (attribute_key, values) in filters {
                if let lastValue = values.last {
                    queryItems.append(URLQueryItem(name: attribute_key, value: lastValue))
                }
            }
        } else {
            if !filters.isEmpty && !isInAllProductsTab {
                for (key, values) in filters {
                    for value in values {
                        queryItems.append(URLQueryItem(name: key, value: value))
                    }
                }
            }
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            await MainActor.run {
                self.isLoading = false
                self.lastError = "آدرس نامعتبر"
            }
            return
        }
        
        print("🌐 [SortViewModel] Special Offers URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "SortViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            print("📡 [SortViewModel] Special Offers HTTP Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                print("❌ [SortViewModel] Special Offers HTTP Error: \(errorBody)")
                throw NSError(domain: "SortViewModel", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
            }
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(offer.self, from: data)
            
            await MainActor.run {
                if self.currentPage == 1 {
                    if decoded.offer.products.count < 1 {
                        self.specialOffersProducts = []
                        self.hasMorePages = false
                    } else {
                        self.specialOffersProducts = decoded.offer.products
                        self.hasMorePages = true
                        self.currentPage += 1
                    }
                } else {
                    if decoded.offer.products.count < 1 {
                        self.hasMorePages = false
                    } else {
                        self.currentPage += 1
                        self.specialOffersProducts.append(contentsOf: decoded.offer.products)
                    }
                }
                self.isLoading = false
            }
            
        } catch {
            print("❌ [SortViewModel] Special Offers Error: \(error)")
            await MainActor.run {
                self.isLoading = false
                self.lastError = "خطا: \(error.localizedDescription)"
            }
        }
    }
}

