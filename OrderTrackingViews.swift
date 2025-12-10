//
//  OrderTrackingViews.swift
//  Customer E-commerce iOS App
//
//  Order history and tracking interface for the customer platform
//

import SwiftUI
import Combine

// MARK: - Order History View
struct OrderHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var orderManager = OrderManager()
    @State private var selectedStatus: String?
    
    var body: some View {
        NavigationView {
            Group {
                if orderManager.isLoading {
                    ProgressView("Loading orders...")
                } else if orderManager.orders.isEmpty {
                    EmptyOrderHistoryView()
                } else {
                    OrderHistoryContentView(
                        orders: orderManager.orders,
                        selectedStatus: $selectedStatus
                    )
                }
            }
            .navigationTitle("Order History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await orderManager.loadOrders()
            }
            .onAppear {
                Task {
                    await orderManager.loadOrders()
                }
            }
        }
    }
}

// MARK: - Empty Order History View
struct EmptyOrderHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bag")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No orders yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Your order history will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Order History Content View
struct OrderHistoryContentView: View {
    let orders: [Order]
    @Binding var selectedStatus: String?
    @State private var showingOrderDetail: Order?
    
    private let statusOptions = [
        "All",
        "Pending",
        "Processing",
        "Shipped",
        "Delivered",
        "Cancelled"
    ]
    
    private var filteredOrders: [Order] {
        guard let selectedStatus = selectedStatus, selectedStatus != "All" else {
            return orders
        }
        
        return orders.filter { order in
            order.status.lowercased() == selectedStatus.lowercased()
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Status Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(statusOptions, id: \.self) { status in
                        StatusFilterButton(
                            title: status,
                            isSelected: selectedStatus == status,
                            onTap: {
                                selectedStatus = status == "All" ? nil : status
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 10)
            
            // Orders List
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(filteredOrders) { order in
                        OrderCard(order: order) {
                            showingOrderDetail = order
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(item: $showingOrderDetail) { order in
            OrderDetailView(order: order)
        }
    }
}

// MARK: - Status Filter Button
struct StatusFilterButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primary : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Order Card
struct OrderCard: View {
    let order: Order
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 15) {
                // Order Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Order #\(order.orderNumber)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(formatDate(order.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    OrderStatusBadge(status: order.status)
                }
                
                // Order Items Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Items:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    ForEach(order.items.prefix(2)) { item in
                        HStack {
                            AsyncImage(url: URL(string: item.product.images.first?.image ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray6))
                            }
                            .frame(width: 40, height: 40)
                            .clipped()
                            .cornerRadius(6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.product.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
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
                        }
                    }
                    
                    if order.items.count > 2 {
                        Text("+ \(order.items.count - 2) more items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                // Order Total
                HStack {
                    Text("Total:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(order.totalToman) تومان")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Delivery Info
                if let address = order.deliveryAddress {
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(address.city), \(address.province)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Order Status Badge
struct OrderStatusBadge: View {
    let status: String
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "pending":
            return .orange
        case "processing":
            return .blue
        case "shipped":
            return .purple
        case "delivered":
            return .green
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private var statusIcon: String {
        switch status.lowercased() {
        case "pending":
            return "clock"
        case "processing":
            return "gear"
        case "shipped":
            return "truck"
        case "delivered":
            return "checkmark.circle"
        case "cancelled":
            return "xmark.circle"
        default:
            return "questionmark.circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption2)
            
            Text(status.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .foregroundColor(statusColor)
        .cornerRadius(8)
    }
}

// MARK: - Order Detail View
struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    @State private var showingCancelConfirmation = false
    @State private var showingReview = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Order Status Timeline
                    OrderStatusTimeline(order: order)
                    
                    // Order Items
                    OrderItemsSection(order: order)
                    
                    // Delivery Information
                    DeliveryInfoSection(order: order)
                    
                    // Payment Information
                    PaymentInfoSection(order: order)
                    
                    // Order Summary
                    OrderSummarySection(order: order)
                    
                    // Action Buttons
                    OrderActionButtons(
                        order: order,
                        showingCancelConfirmation: $showingCancelConfirmation,
                        showingReview: $showingReview
                    )
                }
                .padding()
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Cancel Order", isPresented: $showingCancelConfirmation) {
                Button("Cancel Order", role: .destructive) {
                    cancelOrder()
                }
                Button("Keep Order", role: .cancel) { }
            } message: {
                Text("Are you sure you want to cancel this order? This action cannot be undone.")
            }
            .sheet(isPresented: $showingReview) {
                OrderReviewView(order: order)
            }
        }
    }
    
    private func cancelOrder() {
        // Implement order cancellation
        Task {
            // Call API to cancel order
        }
    }
}

// MARK: - Order Status Timeline
struct OrderStatusTimeline: View {
    let order: Order
    
    private let statusSteps = [
        ("pending", "Order Placed", "clock"),
        ("processing", "Processing", "gear"),
        ("shipped", "Shipped", "truck"),
        ("delivered", "Delivered", "checkmark.circle")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Order Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(Array(statusSteps.enumerated()), id: \.offset) { index, step in
                    OrderStatusStep(
                        status: step.0,
                        title: step.1,
                        icon: step.2,
                        isCompleted: isStepCompleted(step.0),
                        isCurrent: isCurrentStep(step.0),
                        isLast: index == statusSteps.count - 1
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func isStepCompleted(_ stepStatus: String) -> Bool {
        let orderStatus = order.status.lowercased()
        let stepIndex = statusSteps.firstIndex { $0.0 == stepStatus } ?? 0
        let orderIndex = statusSteps.firstIndex { $0.0 == orderStatus } ?? 0
        
        return stepIndex <= orderIndex
    }
    
    private func isCurrentStep(_ stepStatus: String) -> Bool {
        return stepStatus.lowercased() == order.status.lowercased()
    }
}

// MARK: - Order Status Step
struct OrderStatusStep: View {
    let status: String
    let title: String
    let icon: String
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.primary : Color(.systemGray4))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isCompleted ? .white : .secondary)
            }
            
            // Status Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .medium)
                    .foregroundColor(isCompleted ? .primary : .secondary)
                
                if isCurrent {
                    Text(getStatusDescription())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .overlay(
            // Connection Line
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(width: 2, height: isLast ? 0 : 20)
                .offset(x: 16, y: 32),
            alignment: .topLeading
        )
    }
    
    private func getStatusDescription() -> String {
        switch status {
        case "pending":
            return "Your order has been placed and is being prepared"
        case "processing":
            return "Your order is being processed and will be shipped soon"
        case "shipped":
            if let trackingNumber = order.trackingNumber, !trackingNumber.isEmpty {
                return "Tracking: \(trackingNumber)"
            }
            return "Your order is on its way"
        case "delivered":
            return "Your order has been delivered successfully"
        default:
            return ""
        }
    }
}

// MARK: - Order Items Section
struct OrderItemsSection: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Order Items")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(order.items) { item in
                OrderItemRow(item: item)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Order Item Row
struct OrderItemRow: View {
    let item: OrderItem
    
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
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            
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
                
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.totalPriceToman) تومان")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(item.unitPriceToman) تومان each")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Delivery Info Section
struct DeliveryInfoSection: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Delivery Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let address = order.deliveryAddress {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(address.receiverName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(address.fullAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    
                    HStack {
                        Image(systemName: "phone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(address.phone)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Delivery Option
            HStack {
                Image(systemName: "truck")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Delivery: \(order.deliveryOption.capitalized)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Estimated Delivery
            if let estimatedDelivery = order.estimatedDelivery {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Estimated: \(formatDate(estimatedDelivery))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM dd, yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Payment Info Section
struct PaymentInfoSection: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Payment Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Payment Method:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(order.paymentMethod.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Payment Status:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                PaymentStatusBadge(status: order.paymentStatus)
            }
            
            if let paidAt = order.paidAt {
                HStack {
                    Text("Paid On:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(paidAt))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM dd, yyyy 'at' HH:mm"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Payment Status Badge
struct PaymentStatusBadge: View {
    let status: String
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "paid":
            return .green
        case "pending":
            return .orange
        case "failed":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
}

// MARK: - Order Summary Section
struct OrderSummarySection: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(order.subtotalToman) تومان")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Shipping")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(order.shippingCostToman) تومان")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if order.discountAmountToman > 0 {
                    HStack {
                        Text("Discount")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("-\(order.discountAmountToman) تومان")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(order.totalToman) تومان")
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
}

// MARK: - Order Action Buttons
struct OrderActionButtons: View {
    let order: Order
    @Binding var showingCancelConfirmation: Bool
    @Binding var showingReview: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Cancel Order Button (only for pending/processing orders)
            if order.status.lowercased() == "pending" || order.status.lowercased() == "processing" {
                Button(action: {
                    showingCancelConfirmation = true
                }) {
                    Text("Cancel Order")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
            
            // Leave Review Button (only for delivered orders)
            if order.status.lowercased() == "delivered" {
                Button(action: {
                    showingReview = true
                }) {
                    Text("Leave Review")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            // Reorder Button
            Button(action: {
                reorderItems()
            }) {
                Text("Reorder")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
    }
    
    private func reorderItems() {
        // Implement reorder functionality
        // Add all items from this order to cart
    }
}

// MARK: - Order Review View
struct OrderReviewView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    @StateObject private var reviewManager = ReviewManager()
    @State private var reviews: [ProductReview] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(order.items) { item in
                        ProductReviewCard(
                            product: item.product,
                            variant: item.variant,
                            onReviewSubmitted: { rating, title, comment in
                                submitReview(
                                    product: item.product,
                                    variant: item.variant,
                                    rating: rating,
                                    title: title,
                                    comment: comment
                                )
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Leave Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitReview(product: Product, variant: ProductVariant?, rating: Int, title: String, comment: String) {
        Task {
            await reviewManager.submitReview(
                productId: product.id,
                variantId: variant?.id,
                rating: rating,
                title: title,
                comment: comment
            )
        }
    }
}

// MARK: - Product Review Card
struct ProductReviewCard: View {
    let product: Product
    let variant: ProductVariant?
    let onReviewSubmitted: (Int, String, String) -> Void
    
    @State private var rating = 0
    @State private var title = ""
    @State private var comment = ""
    @State private var showingReviewForm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 15) {
                AsyncImage(url: URL(string: product.images.first?.image ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray6))
                }
                .frame(width: 60, height: 60)
                .clipped()
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    if let variant = variant {
                        Text(variant.variantName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            if showingReviewForm {
                VStack(alignment: .leading, spacing: 15) {
                    // Rating Stars
                    HStack {
                        Text("Rating:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 5) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    rating = star
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                    
                    // Review Title
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Title (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter a title for your review", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Review Comment
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Comment")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Share your experience with this product", text: $comment, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    
                    // Submit Button
                    Button(action: {
                        onReviewSubmitted(rating, title, comment)
                        showingReviewForm = false
                    }) {
                        Text("Submit Review")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(rating > 0 ? Color.primary : Color.secondary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(rating == 0)
                }
            } else {
                Button(action: {
                    showingReviewForm = true
                }) {
                    Text("Write a Review")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Data Managers
class OrderManager: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiManager = APIManager.shared
    
    func loadOrders() async {
        isLoading = true
        
        do {
            let url = URL(string: "\(apiManager.baseURL)/orders/")!
            let request = apiManager.createRequest(url: url)
            
            let response: [Order] = try await apiManager.performRequest(request, responseType: [Order].self)
            
            await MainActor.run {
                self.orders = response
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

class ReviewManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiManager = APIManager.shared
    
    func submitReview(productId: Int, variantId: Int?, rating: Int, title: String, comment: String) async {
        isLoading = true
        
        do {
            let reviewData: [String: Any] = [
                "rating": rating,
                "title": title,
                "comment": comment
            ]
            
            if let variantId = variantId {
                reviewData["variant_id"] = variantId
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: reviewData)
            
            let url = URL(string: "\(apiManager.baseURL)/products/\(productId)/reviews/")!
            let request = apiManager.createRequest(url: url, method: "POST", body: jsonData)
            
            await apiManager.performRequest(request, responseType: [String: String].self)
            
            await MainActor.run {
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

// MARK: - Product Review Model
struct ProductReview: Codable, Identifiable {
    let id: Int
    let customerName: String
    let rating: Int
    let title: String
    let comment: String
    let isVerifiedPurchase: Bool
    let isFeatured: Bool
    let createdAt: String
    let images: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, rating, title, comment, images, createdAt
        case customerName = "customer_name"
        case isVerifiedPurchase = "is_verified_purchase"
        case isFeatured = "is_featured"
        case createdAt = "created_at"
    }
}
