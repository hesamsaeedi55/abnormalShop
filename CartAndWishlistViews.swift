//
//  CartAndWishlistViews.swift
//  Customer E-commerce iOS App
//
//  Cart and wishlist management screens for the customer platform
//

import SwiftUI
import Combine

// MARK: - Cart View
struct CartView: View {
    @EnvironmentObject var cartManager: CartManager
    @State private var showingCheckout = false
    @State private var showingEmptyCart = false
    
    var body: some View {
        NavigationView {
            Group {
                if cartManager.isLoading {
                    ProgressView("Loading cart...")
                } else if cartManager.cart?.items.isEmpty ?? true {
                    EmptyCartView()
                } else {
                    CartContentView(showingCheckout: $showingCheckout)
                }
            }
            .navigationTitle("Shopping Cart")
            .refreshable {
                cartManager.loadCart()
            }
            .sheet(isPresented: $showingCheckout) {
                CheckoutView()
            }
            .onAppear {
                cartManager.loadCart()
            }
        }
    }
}

// MARK: - Empty Cart View
struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Your cart is empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Add some products to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Cart Content View
struct CartContentView: View {
    @EnvironmentObject var cartManager: CartManager
    @Binding var showingCheckout: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Cart Items
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(cartManager.cart?.items ?? []) { item in
                        CartItemRow(item: item)
                    }
                }
                .padding()
            }
            
            // Cart Summary
            CartSummaryView(showingCheckout: $showingCheckout)
        }
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let item: CartItem
    @EnvironmentObject var cartManager: CartManager
    @State private var showingProductDetail = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Product Image
            AsyncImage(url: URL(string: item.product.images.first?.image ?? "")) { image in
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
            .frame(width: 80, height: 80)
            .clipped()
            .cornerRadius(8)
            .onTapGesture {
                showingProductDetail = true
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 5) {
                Text(item.product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let variant = item.variant {
                    Text(variant.variantName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(item.totalPriceToman) تومان")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Quantity Controls
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Button(action: {
                        cartManager.updateCartItem(itemId: item.id, quantity: item.quantity - 1)
                    }) {
                        Image(systemName: "minus")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .disabled(item.quantity <= 1)
                    
                    Text("\(item.quantity)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 20)
                    
                    Button(action: {
                        cartManager.updateCartItem(itemId: item.id, quantity: item.quantity + 1)
                    }) {
                        Image(systemName: "plus")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
                
                // Remove Button
                Button(action: {
                    cartManager.removeFromCart(itemId: item.id)
                }) {
                    Text("Remove")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingProductDetail) {
            ProductDetailView(product: item.product)
        }
    }
}

// MARK: - Cart Summary View
struct CartSummaryView: View {
    @EnvironmentObject var cartManager: CartManager
    @Binding var showingCheckout: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Divider()
            
            // Summary Details
            VStack(spacing: 10) {
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.cart?.totalPriceToman ?? 0) تومان")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Shipping")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Calculated at checkout")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(cartManager.cart?.totalPriceToman ?? 0) تومان")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Checkout Button
            Button(action: {
                showingCheckout = true
            }) {
                Text("Proceed to Checkout")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Wishlist View
struct WishlistView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @EnvironmentObject var cartManager: CartManager
    @State private var showingEmptyWishlist = false
    
    var body: some View {
        NavigationView {
            Group {
                if wishlistManager.isLoading {
                    ProgressView("Loading wishlist...")
                } else if wishlistManager.wishlistItems.isEmpty {
                    EmptyWishlistView()
                } else {
                    WishlistContentView()
                }
            }
            .navigationTitle("Wishlist")
            .refreshable {
                wishlistManager.loadWishlist()
            }
            .onAppear {
                wishlistManager.loadWishlist()
            }
        }
    }
}

// MARK: - Empty Wishlist View
struct EmptyWishlistView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Your wishlist is empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Save products you love for later")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Wishlist Content View
struct WishlistContentView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(wishlistManager.wishlistItems) { item in
                    WishlistItemCard(item: item)
                }
            }
            .padding()
        }
    }
}

// MARK: - Wishlist Item Card
struct WishlistItemCard: View {
    let item: WishlistItem
    @EnvironmentObject var wishlistManager: WishlistManager
    @EnvironmentObject var cartManager: CartManager
    @State private var showingProductDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Product Image
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: item.product.images.first?.image ?? "")) { image in
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
                .onTapGesture {
                    showingProductDetail = true
                }
                
                // Remove from Wishlist Button
                Button(action: {
                    wishlistManager.removeFromWishlist(
                        productId: item.product.id,
                        variantId: item.variant?.id
                    )
                }) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 5) {
                Text(item.product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let variant = item.variant {
                    Text(variant.variantName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("\(item.product.priceToman) تومان")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Add to Cart Button
            Button(action: {
                cartManager.addToCart(
                    productId: item.product.id,
                    variantId: item.variant?.id
                )
            }) {
                Text("Add to Cart")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showingProductDetail) {
            ProductDetailView(product: item.product)
        }
    }
}

// MARK: - Checkout View
struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var checkoutManager = CheckoutManager()
    @State private var selectedAddress: Address?
    @State private var deliveryOption = "standard"
    @State private var paymentMethod = "cod"
    @State private var discountCode = ""
    @State private var showingAddressSelection = false
    @State private var showingOrderConfirmation = false
    @State private var createdOrder: Order?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Order Summary
                    CheckoutOrderSummary()
                    
                    // Delivery Address
                    CheckoutAddressSection(
                        selectedAddress: $selectedAddress,
                        showingAddressSelection: $showingAddressSelection
                    )
                    
                    // Delivery Options
                    CheckoutDeliverySection(deliveryOption: $deliveryOption)
                    
                    // Payment Method
                    CheckoutPaymentSection(paymentMethod: $paymentMethod)
                    
                    // Discount Code
                    CheckoutDiscountSection(discountCode: $discountCode)
                    
                    // Order Total
                    CheckoutTotalSection()
                }
                .padding()
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Place Order Button
                Button(action: placeOrder) {
                    HStack {
                        Text("Place Order")
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(getTotalPrice()) تومان")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.primary : Color.secondary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || checkoutManager.isLoading)
                .padding()
                .background(Color(.systemBackground))
            }
            .sheet(isPresented: $showingAddressSelection) {
                AddressSelectionView(selectedAddress: $selectedAddress)
            }
            .sheet(isPresented: $showingOrderConfirmation) {
                if let order = createdOrder {
                    OrderConfirmationView(order: order)
                }
            }
            .onAppear {
                loadDefaultAddress()
            }
        }
    }
    
    private var isFormValid: Bool {
        selectedAddress != nil
    }
    
    private func getTotalPrice() -> Int {
        let subtotal = cartManager.cart?.totalPriceToman ?? 0
        let shippingCost = getShippingCost()
        return subtotal + shippingCost
    }
    
    private func getShippingCost() -> Int {
        switch deliveryOption {
        case "express":
            return 50000 // 50,000 Toman for express
        case "standard":
            return 25000 // 25,000 Toman for standard
        default:
            return 25000
        }
    }
    
    private func loadDefaultAddress() {
        // Load user's default address
        // Implementation depends on your address management
    }
    
    private func placeOrder() {
        guard let address = selectedAddress else { return }
        
        Task {
            do {
                let orderData: [String: Any] = [
                    "address_id": address.id,
                    "delivery_option": deliveryOption,
                    "payment_method": paymentMethod,
                    "discount_code": discountCode
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: orderData)
                
                let url = URL(string: "\(APIManager.shared.baseURL)/checkout/")!
                let request = APIManager.shared.createRequest(url: url, method: "POST", body: jsonData)
                
                let order: Order = try await APIManager.shared.performRequest(request, responseType: Order.self)
                
                await MainActor.run {
                    createdOrder = order
                    showingOrderConfirmation = true
                }
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Checkout Order Summary
struct CheckoutOrderSummary: View {
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Order Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(cartManager.cart?.items ?? []) { item in
                HStack {
                    AsyncImage(url: URL(string: item.product.images.first?.image ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray6))
                    }
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(6)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.product.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        if let variant = item.variant {
                            Text(variant.variantName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Qty: \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(item.totalPriceToman) تومان")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Checkout Address Section
struct CheckoutAddressSection: View {
    @Binding var selectedAddress: Address?
    @Binding var showingAddressSelection: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Delivery Address")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let address = selectedAddress {
                VStack(alignment: .leading, spacing: 5) {
                    Text(address.receiverName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(address.fullAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    Text(address.phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                Button(action: {
                    showingAddressSelection = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Select Address")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Checkout Delivery Section
struct CheckoutDeliverySection: View {
    @Binding var deliveryOption: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Delivery Option")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                DeliveryOptionRow(
                    title: "Standard Delivery",
                    description: "3-5 business days",
                    price: "25,000 تومان",
                    isSelected: deliveryOption == "standard",
                    onTap: { deliveryOption = "standard" }
                )
                
                DeliveryOptionRow(
                    title: "Express Delivery",
                    description: "1-2 business days",
                    price: "50,000 تومان",
                    isSelected: deliveryOption == "express",
                    onTap: { deliveryOption = "express" }
                )
            }
        }
    }
}

// MARK: - Delivery Option Row
struct DeliveryOptionRow: View {
    let title: String
    let description: String
    let price: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(price)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding()
            .background(isSelected ? Color.primary.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Checkout Payment Section
struct CheckoutPaymentSection: View {
    @Binding var paymentMethod: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Payment Method")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 10) {
                PaymentMethodRow(
                    title: "Cash on Delivery",
                    description: "Pay when your order arrives",
                    icon: "banknote",
                    isSelected: paymentMethod == "cod",
                    onTap: { paymentMethod = "cod" }
                )
                
                PaymentMethodRow(
                    title: "Online Payment",
                    description: "Pay securely online",
                    icon: "creditcard",
                    isSelected: paymentMethod == "online",
                    onTap: { paymentMethod = "online" }
                )
            }
        }
    }
}

// MARK: - Payment Method Row
struct PaymentMethodRow: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding()
            .background(isSelected ? Color.primary.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Checkout Discount Section
struct CheckoutDiscountSection: View {
    @Binding var discountCode: String
    @State private var showingDiscountField = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Discount Code")
                .font(.headline)
                .fontWeight(.semibold)
            
            if showingDiscountField {
                HStack {
                    TextField("Enter discount code", text: $discountCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Apply") {
                        // Apply discount code
                        showingDiscountField = false
                    }
                    .foregroundColor(.primary)
                }
            } else {
                Button(action: {
                    showingDiscountField = true
                }) {
                    HStack {
                        Image(systemName: "tag")
                        Text("Add Discount Code")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Checkout Total Section
struct CheckoutTotalSection: View {
    @EnvironmentObject var cartManager: CartManager
    @State private var deliveryOption = "standard"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order Total")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(cartManager.cart?.totalPriceToman ?? 0) تومان")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Shipping")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(getShippingCost()) تومان")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(getTotalPrice()) تومان")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getShippingCost() -> Int {
        switch deliveryOption {
        case "express":
            return 50000
        case "standard":
            return 25000
        default:
            return 25000
        }
    }
    
    private func getTotalPrice() -> Int {
        let subtotal = cartManager.cart?.totalPriceToman ?? 0
        return subtotal + getShippingCost()
    }
}

// MARK: - Address Selection View
struct AddressSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAddress: Address?
    @StateObject private var addressManager = AddressManager()
    
    var body: some View {
        NavigationView {
            Group {
                if addressManager.isLoading {
                    ProgressView("Loading addresses...")
                } else if addressManager.addresses.isEmpty {
                    EmptyAddressView()
                } else {
                    List(addressManager.addresses) { address in
                        AddressRow(
                            address: address,
                            isSelected: selectedAddress?.id == address.id,
                            onTap: {
                                selectedAddress = address
                                dismiss()
                            }
                        )
                    }
                }
            }
            .navigationTitle("Select Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                addressManager.loadAddresses()
            }
        }
    }
}

// MARK: - Empty Address View
struct EmptyAddressView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "location")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No addresses found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Add an address to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Address Row
struct AddressRow: View {
    let address: Address
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(address.receiverName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(address.fullAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(address.phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding()
            .background(isSelected ? Color.primary.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Order Confirmation View
struct OrderConfirmationView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                // Order Confirmation
                VStack(spacing: 10) {
                    Text("Order Placed Successfully!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Order #\(order.orderNumber)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("We'll send you a confirmation email shortly")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Continue Shopping Button
                Button(action: {
                    dismiss()
                }) {
                    Text("Continue Shopping")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Order Confirmed")
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
class CheckoutManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
}

class AddressManager: ObservableObject {
    @Published var addresses: [Address] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiManager = APIManager.shared
    
    func loadAddresses() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let url = URL(string: "\(apiManager.baseURL)/accounts/customer/addresses/")!
                let request = apiManager.createRequest(url: url)
                
                let response: AddressesResponse = try await apiManager.performRequest(request, responseType: AddressesResponse.self)
                
                await MainActor.run {
                    self.addresses = response.addresses
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch let error as APIError {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("Error loading addresses: \(error.localizedDescription)")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to load addresses. Please try again later."
                    print("Error loading addresses: \(error)")
                }
            }
        }
    }
}
