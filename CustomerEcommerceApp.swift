//
//  CustomerEcommerceApp.swift
//  Customer E-commerce iOS App
//
//  Main app structure and architecture for the customer platform
//

import SwiftUI
import Combine

// MARK: - App Entry Point
@main
struct CustomerEcommerceApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var cartManager = CartManager()
    @StateObject private var wishlistManager = WishlistManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(cartManager)
                .environmentObject(wishlistManager)
                .environmentObject(notificationManager)
                .onAppear {
                    // Initialize managers
                    authManager.checkAuthStatus()
                    cartManager.loadCart()
                    wishlistManager.loadWishlist()
                    notificationManager.loadNotifications()
                }
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .id("authenticated")
            } else {
                AuthenticationView()
                    .id("unauthenticated")
            }
        }
    }
}

// MARK: - Main Tab Navigation
struct MainTabView: View {
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var wishlistManager: WishlistManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CategoryView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Categories")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            CartView()
                .tabItem {
                    ZStack {
                        Image(systemName: "cart.fill")
                        if cartManager.totalItems > 0 {
                            Text("\(cartManager.totalItems)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.red))
                                .offset(x: 10, y: -10)
                        }
                    }
                    Text("Cart")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.primary)
    }
}

// MARK: - Data Models
struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let priceToman: Int
    let priceUsd: Double?
    let category: Int
    let supplier: Int?
    let isActive: Bool
    let createdAt: String
    let variants: [ProductVariant]
    let images: [ProductImage]
    let averageRating: Double?
    let reviewCount: Int
    let isInWishlist: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, supplier, variants, images
        case priceToman = "price_toman"
        case priceUsd = "price_usd"
        case isActive = "is_active"
        case createdAt = "created_at"
        case averageRating = "average_rating"
        case reviewCount = "review_count"
        case isInWishlist = "is_in_wishlist"
    }
}

struct ProductVariant: Codable, Identifiable {
    let id: Int
    let sku: String
    let variantName: String?
    let priceToman: Int
    let priceUsd: Double?
    let stockQuantity: Int
    let isActive: Bool
    let images: [ProductImage]?
    
    enum CodingKeys: String, CodingKey {
        case id, sku, stockQuantity, images
        case variantName = "variant_name"
        case priceToman = "price_toman"
        case priceUsd = "price_usd"
        case isActive = "is_active"
    }
}

struct ProductImage: Codable, Identifiable {
    let id: Int
    let image: String
    let isPrimary: Bool
    let displayOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case image
        case url  // Variant images use "url" field
        case isPrimary = "is_primary"
        case displayOrder = "display_order"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        
        // Handle both "image" and "url" fields (variant images use "url", product images use "image")
        if let imageValue = try? container.decode(String.self, forKey: .image) {
            image = imageValue
        } else if let urlValue = try? container.decode(String.self, forKey: .url) {
            image = urlValue
        } else {
            image = ""
        }
        
        isPrimary = try container.decodeIfPresent(Bool.self, forKey: .isPrimary) ?? false
        displayOrder = try container.decodeIfPresent(Int.self, forKey: .displayOrder) ?? 1
    }
}

struct CartItem: Codable, Identifiable {
    let id: Int
    let product: Product
    let variant: ProductVariant?
    let quantity: Int
    let totalPriceToman: Int
    let totalPriceUsd: Double?
    let addedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, product, variant, quantity, addedAt
        case totalPriceToman = "total_price_toman"
        case totalPriceUsd = "total_price_usd"
        case addedAt = "added_at"
    }
}

struct Cart: Codable {
    let id: Int
    let items: [CartItem]
    let totalItems: Int
    let totalPriceToman: Int
    let totalPriceUsd: Double?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, items, createdAt, updatedAt
        case totalItems = "total_items"
        case totalPriceToman = "total_price_toman"
        case totalPriceUsd = "total_price_usd"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WishlistItem: Codable, Identifiable {
    let id: Int
    let product: Product
    let variant: ProductVariant?
    let addedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, product, variant
        case addedAt = "added_at"
    }
}

struct Order: Codable, Identifiable {
    let id: Int
    let orderNumber: String
    let status: String
    let paymentMethod: String
    let paymentStatus: String
    let subtotalToman: Int
    let subtotalUsd: Double?
    let shippingCostToman: Int
    let shippingCostUsd: Double?
    let discountAmountToman: Int
    let discountAmountUsd: Double?
    let totalToman: Int
    let totalUsd: Double?
    let deliveryAddress: Address?
    let deliveryOption: String
    let deliveryStatus: String
    let trackingNumber: String?
    let estimatedDelivery: String?
    let deliveredAt: String?
    let createdAt: String
    let updatedAt: String
    let paidAt: String?
    let notes: String
    let discountCode: String
    let items: [OrderItem]
    
    enum CodingKeys: String, CodingKey {
        case id, status, notes, items
        case orderNumber = "order_number"
        case paymentMethod = "payment_method"
        case paymentStatus = "payment_status"
        case subtotalToman = "subtotal_toman"
        case subtotalUsd = "subtotal_usd"
        case shippingCostToman = "shipping_cost_toman"
        case shippingCostUsd = "shipping_cost_usd"
        case discountAmountToman = "discount_amount_toman"
        case discountAmountUsd = "discount_amount_usd"
        case totalToman = "total_toman"
        case totalUsd = "total_usd"
        case deliveryAddress = "delivery_address"
        case deliveryOption = "delivery_option"
        case deliveryStatus = "delivery_status"
        case trackingNumber = "tracking_number"
        case estimatedDelivery = "estimated_delivery"
        case deliveredAt = "delivered_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case paidAt = "paid_at"
        case discountCode = "discount_code"
    }
}

struct OrderItem: Codable, Identifiable {
    let id: Int
    let product: Product
    let variant: ProductVariant?
    let quantity: Int
    let unitPriceToman: Int
    let unitPriceUsd: Double?
    let totalPriceToman: Int
    let totalPriceUsd: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, product, variant, quantity
        case unitPriceToman = "unit_price_toman"
        case unitPriceUsd = "unit_price_usd"
        case totalPriceToman = "total_price_toman"
        case totalPriceUsd = "total_price_usd"
    }
}

// Response wrapper for addresses API
struct AddressesResponse: Codable {
    let addresses: [Address]
}

struct Address: Codable, Identifiable, Equatable {
    var id: Int
    var label: String
    var receiverName: String
    var streetAddress: String
    var city: String
    var province: String
    var vahed: String
    var phone: String
    var country: String
    var postalCode: String
    var createdAt: String
    var updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, label, city, phone, country
        case receiverName = "receiver_name"
        case streetAddress = "street_address"
        case province = "state"  // API returns "state" but we use "province" internally
        case vahed = "unit"  // API returns "unit" but we use "vahed" internally
        case postalCode = "postal_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to ensure country defaults to "ایران"
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        receiverName = try container.decodeIfPresent(String.self, forKey: .receiverName) ?? ""
        streetAddress = try container.decodeIfPresent(String.self, forKey: .streetAddress) ?? ""
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        province = try container.decodeIfPresent(String.self, forKey: .province) ?? ""
        vahed = try container.decodeIfPresent(String.self, forKey: .vahed) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        let decodedCountry = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
        country = decodedCountry.isEmpty ? "ایران" : decodedCountry
        postalCode = try container.decodeIfPresent(String.self, forKey: .postalCode) ?? ""
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }
    
    // Computed properties for snake_case access (for compatibility with existing code)
    // These are read-write computed properties that sync with the underlying stored properties
    var receiver_name: String {
        get { receiverName }
        set { receiverName = newValue }
    }
    
    var street_address: String {
        get { streetAddress }
        set { streetAddress = newValue }
    }
    
    var postal_code: String {
        get { postalCode }
        set { postalCode = newValue }
    }
    
    var state: String {
        get { province }
        set { province = newValue }
    }
    
    var unit: String {
        get { vahed }
        set { vahed = newValue }
    }
    
    var full_address: String {
        var parts: [String] = []
        if !receiverName.isEmpty { parts.append(receiverName) }
        if !streetAddress.isEmpty { parts.append(streetAddress) }
        if !vahed.isEmpty { parts.append("واحد \(vahed)") }
        if !city.isEmpty { parts.append(city) }
        if !province.isEmpty { parts.append(province) }
        if !country.isEmpty { parts.append(country) }
        if !postalCode.isEmpty { parts.append(postalCode) }
        if !phone.isEmpty { parts.append("تلفن \(phone)") }
        return parts.joined(separator: ", ")
    }
    
    // Initializer that accepts snake_case properties
    init(id: Int = 0, label: String = "", receiver_name: String = "", country: String = "ایران", state: String = "", city: String = "", street_address: String = "", unit: String = "", postal_code: String = "", phone: String = "", full_address: String = "") {
        self.id = id
        self.label = label
        self.receiverName = receiver_name
        self.country = country.isEmpty ? "ایران" : country
        self.province = state
        self.city = city
        self.streetAddress = street_address
        self.vahed = unit
        self.postalCode = postal_code
        self.phone = phone
        self.createdAt = ""
        self.updatedAt = ""
    }
}

struct User: Codable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct AuthTokens: Codable {
    let access: String
    let refresh: String
}

struct AuthResponse: Codable {
    let user: User
    let tokens: AuthTokens
}

// MARK: - API Manager
class APIManager: ObservableObject {
    static let shared = APIManager()
    
    private let baseURL = "https://myshop-backend-an7h.onrender.com"
    private var accessToken: String?
    
    // Timeout configuration
    private let requestTimeout: TimeInterval = 30.0  // 30 seconds for request
    private let resourceTimeout: TimeInterval = 60.0  // 60 seconds for resource (downloads)
    
    // URLSession with custom timeout configuration
    private let urlSession: URLSession
    
    // Device ID for guest users (persists across app launches)
    private var deviceID: String {
        let key = "device_id"
        if let storedID = UserDefaults.standard.string(forKey: key) {
            return storedID
        }
        // Generate and store device ID
        let newID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }
    
    private init() {
        // Configure URLSession with timeouts
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = resourceTimeout
        config.waitsForConnectivity = true  // Wait for network to become available
        self.urlSession = URLSession(configuration: config)
    }
    
    func setAccessToken(_ token: String) {
        accessToken = token
    }
    
    func clearAccessToken() {
        accessToken = nil
    }
    
    private func createRequest(url: URL, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = requestTimeout  // Set per-request timeout
        
        // Add authentication token if available
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Always send device ID header (for guest cart support)
        request.setValue(deviceID, forHTTPHeaderField: "X-Device-ID")
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                if httpResponse.statusCode == 429 {
                    // Try to extract error message from response
                    if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                       let detail = errorResponse["detail"] {
                        throw APIError.rateLimitExceeded(detail)
                    }
                    throw APIError.rateLimitExceeded("Too many requests. Please try again later.")
                }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(responseType, from: data)
            } catch {
                throw APIError.decodingError
            }
        } catch let error as APIError {
            // Re-throw APIError as-is
            throw error
        } catch {
            // Convert URL errors (including timeouts) to APIError
            throw APIError.fromURLError(error)
        }
    }
}

enum APIError: Error {
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError
    case networkError
    case rateLimitExceeded(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection error"
        case .rateLimitExceeded(let message):
            return message
        }
    }
}

// MARK: - Network Timeout Error
extension APIError {
    static func fromURLError(_ error: Error) -> APIError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .networkError  // Will show "Network connection error"
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError
            default:
                return .networkError
            }
        }
        return .networkError
    }
}

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiManager = APIManager.shared
    
    func checkAuthStatus() {
        // Check for stored tokens
        if let token = UserDefaults.standard.string(forKey: "access_token") {
            apiManager.setAccessToken(token)
            isAuthenticated = true
            loadUserProfile()
        }
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loginData = ["email": email, "password": password]
            let jsonData = try JSONSerialization.data(withJSONObject: loginData)
            
            let url = URL(string: "\(apiManager.baseURL)/login/")!
            let request = apiManager.createRequest(url: url, method: "POST", body: jsonData)
            
            let response: AuthResponse = try await apiManager.performRequest(request, responseType: AuthResponse.self)
            
            // Store tokens
            UserDefaults.standard.set(response.tokens.access, forKey: "access_token")
            UserDefaults.standard.set(response.tokens.refresh, forKey: "refresh_token")
            
            apiManager.setAccessToken(response.tokens.access)
            currentUser = response.user
            isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register(email: String, password: String, firstName: String, lastName: String, phoneNumber: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let registerData = [
                "email": email,
                "password": password,
                "password_confirm": password,
                "first_name": firstName,
                "last_name": lastName,
                "phone_number": phoneNumber
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: registerData)
            
            let url = URL(string: "\(apiManager.baseURL)/register/")!
            let request = apiManager.createRequest(url: url, method: "POST", body: jsonData)
            
            let response: AuthResponse = try await apiManager.performRequest(request, responseType: AuthResponse.self)
            
            // Store tokens
            UserDefaults.standard.set(response.tokens.access, forKey: "access_token")
            UserDefaults.standard.set(response.tokens.refresh, forKey: "refresh_token")
            
            apiManager.setAccessToken(response.tokens.access)
            currentUser = response.user
            isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        apiManager.clearAccessToken()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func loadUserProfile() {
        // Load user profile from stored data or API
        // Implementation depends on your needs
    }
}

// MARK: - Cart Manager
class CartManager: ObservableObject {
    @Published var cart: Cart?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiManager = APIManager.shared
    
    var totalItems: Int {
        cart?.totalItems ?? 0
    }
    
    var totalPrice: Int {
        cart?.totalPriceToman ?? 0
    }
    
    func loadCart() {
        // Works for both authenticated and guest users (device ID is sent automatically)
        isLoading = true
        
        Task {
            do {
                let url = URL(string: "\(apiManager.baseURL)/cart/")!
                let request = apiManager.createRequest(url: url)
                
                let cart: Cart = try await apiManager.performRequest(request, responseType: Cart.self)
                
                await MainActor.run {
                    self.cart = cart
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func addToCart(productId: Int, variantId: Int? = nil, quantity: Int = 1) {
        Task {
            do {
                let cartData: [String: Any] = [
                    "product_id": productId,
                    "quantity": quantity
                ]
                
                if let variantId = variantId {
                    cartData["variant_id"] = variantId
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: cartData)
                
                let url = URL(string: "\(apiManager.baseURL)/cart/")!
                let request = apiManager.createRequest(url: url, method: "POST", body: jsonData)
                
                let updatedCart: Cart = try await apiManager.performRequest(request, responseType: Cart.self)
                
                await MainActor.run {
                    self.cart = updatedCart
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateCartItem(itemId: Int, quantity: Int) {
        Task {
            do {
                let updateData = [
                    "item_id": itemId,
                    "quantity": quantity
                ] as [String : Any]
                
                let jsonData = try JSONSerialization.data(withJSONObject: updateData)
                
                let url = URL(string: "\(apiManager.baseURL)/cart/")!
                let request = apiManager.createRequest(url: url, method: "PUT", body: jsonData)
                
                let updatedCart: Cart = try await apiManager.performRequest(request, responseType: Cart.self)
                
                await MainActor.run {
                    self.cart = updatedCart
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func removeFromCart(itemId: Int) {
        Task {
            do {
                let removeData = ["item_id": itemId]
                let jsonData = try JSONSerialization.data(withJSONObject: removeData)
                
                // Use the correct endpoint: /shop/api/customer/cart/remove/ or /shop/api/customer/cart/
                // Check if baseURL already includes /shop
                let cartRemoveURL: String
                if apiManager.baseURL.contains("/shop") {
                    cartRemoveURL = "\(apiManager.baseURL)/cart/remove/"
                } else {
                    // If baseURL is like http://127.0.0.1:8000/api/customer, use the full path
                    cartRemoveURL = apiManager.baseURL.replacingOccurrences(of: "/api/customer", with: "/shop/api/customer/cart/remove/")
                }
                
                let url = URL(string: cartRemoveURL)!
                let request = apiManager.createRequest(url: url, method: "DELETE", body: jsonData)
                
                let updatedCart: Cart = try await apiManager.performRequest(request, responseType: Cart.self)
                
                await MainActor.run {
                    self.cart = updatedCart
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    print("❌ Error removing from cart: \(error)")
                }
            }
        }
    }
}

// MARK: - Wishlist Manager
class WishlistManager: ObservableObject {
    @Published var wishlistItems: [WishlistItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiManager = APIManager.shared
    
    func loadWishlist() {
        guard apiManager.accessToken != nil else { return }
        
        isLoading = true
        
        Task {
            do {
                let url = URL(string: "\(apiManager.baseURL)/wishlist/")!
                let request = apiManager.createRequest(url: url)
                
                let items: [WishlistItem] = try await apiManager.performRequest(request, responseType: [WishlistItem].self)
                
                await MainActor.run {
                    self.wishlistItems = items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func addToWishlist(productId: Int, variantId: Int? = nil) {
        Task {
            do {
                let wishlistData: [String: Any] = [
                    "product_id": productId
                ]
                
                if let variantId = variantId {
                    wishlistData["variant_id"] = variantId
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: wishlistData)
                
                let url = URL(string: "\(apiManager.baseURL)/wishlist/")!
                let request = apiManager.createRequest(url: url, method: "POST", body: jsonData)
                
                let newItem: WishlistItem = try await apiManager.performRequest(request, responseType: WishlistItem.self)
                
                await MainActor.run {
                    self.wishlistItems.append(newItem)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func removeFromWishlist(productId: Int, variantId: Int? = nil) {
        Task {
            do {
                let removeData: [String: Any] = [
                    "product_id": productId
                ]
                
                if let variantId = variantId {
                    removeData["variant_id"] = variantId
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: removeData)
                
                let url = URL(string: "\(apiManager.baseURL)/wishlist/")!
                let request = apiManager.createRequest(url: url, method: "DELETE", body: jsonData)
                
                await apiManager.performRequest(request, responseType: [String: String].self)
                
                await MainActor.run {
                    self.wishlistItems.removeAll { item in
                        item.product.id == productId && item.variant?.id == variantId
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func isInWishlist(productId: Int, variantId: Int? = nil) -> Bool {
        return wishlistItems.contains { item in
            item.product.id == productId && item.variant?.id == variantId
        }
    }
}

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    @Published var notifications: [CustomerNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading = false
    
    private let apiManager = APIManager.shared
    
    func loadNotifications() {
        guard apiManager.accessToken != nil else { return }
        
        isLoading = true
        
        Task {
            do {
                let url = URL(string: "\(apiManager.baseURL)/notifications/")!
                let request = apiManager.createRequest(url: url)
                
                let notifications: [CustomerNotification] = try await apiManager.performRequest(request, responseType: [CustomerNotification].self)
                
                await MainActor.run {
                    self.notifications = notifications
                    self.unreadCount = notifications.filter { !$0.isRead }.count
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func markAsRead(notificationId: Int) {
        Task {
            do {
                let url = URL(string: "\(apiManager.baseURL)/notifications/\(notificationId)/read/")!
                let request = apiManager.createRequest(url: url, method: "POST")
                
                await apiManager.performRequest(request, responseType: [String: String].self)
                
                await MainActor.run {
                    if let index = self.notifications.firstIndex(where: { $0.id == notificationId }) {
                        self.notifications[index].isRead = true
                        self.unreadCount = max(0, self.unreadCount - 1)
                    }
                }
            } catch {
                // Handle error silently for notifications
            }
        }
    }
}

struct CustomerNotification: Codable, Identifiable {
    let id: Int
    let notificationType: String
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: String
    let readAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, message, createdAt, readAt
        case notificationType = "notification_type"
        case isRead = "is_read"
        case createdAt = "created_at"
        case readAt = "read_at"
    }
}

// MARK: - Price Formatting Extensions
extension Int {
    func getFormattedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.locale = Locale(identifier: "fa_IR") // Persian digits
        
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "۰"
        return "\(formatted) تومان"
    }
}

extension Optional where Wrapped == Int {
    func getFormattedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.locale = Locale(identifier: "fa_IR") // Persian digits
        
        if let price = self {
            let formatted = formatter.string(from: NSNumber(value: price)) ?? "۰"
            return "\(formatted) تومان"
        } else {
            return "نامشخص"
        }
    }
}

extension Double {
    func getFormattedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "fa_IR") // Persian digits
        
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "۰"
        return "\(formatted) تومان"
    }
}

extension Optional where Wrapped == Double {
    func getFormattedPrice() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "fa_IR") // Persian digits
        
        if let price = self {
            let formatted = formatter.string(from: NSNumber(value: price)) ?? "۰"
            return "\(formatted) تومان"
        } else {
            return "نامشخص"
        }
    }
}

extension Product {
    func getFormattedPrice() -> String {
        return priceToman.getFormattedPrice()
    }
}

extension ProductVariant {
    func getFormattedPrice() -> String {
        return priceToman.getFormattedPrice()
    }
}

