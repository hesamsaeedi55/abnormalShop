// FIXED VERSION - Simplified postAddress for non-critical operations
// No cancellation support - operations should be fast (< 15 seconds)
// Uses NetworkErrorHandler for consistent error handling
// Add this to your AddressViewModel class
// Requires: import Network, NetworkErrorHandler.swift

import Network

@MainActor
class AddressViewModel: ObservableObject {
    @Published var isPosting = false
    @Published var isDeleting = false
    @Published var isAddressSaved = false
    @Published var postingErrorMessage: String?  // Error message for user
    @Published var showPostingError = false  // Show error alert
    
    func postAddress(address: Address) async {
        // Prevent concurrent operations
        guard !isPosting else { return }
        
        isPosting = true
        postingErrorMessage = nil
        showPostingError = false
        
        defer {
            isPosting = false
        }
        
        // Check internet connectivity first (more reliable than error parsing)
        // Check twice with small delay to ensure stable connection (not just momentary)
        let hasInternet1 = await checkInternetConnection()
        if !hasInternet1 {
            postingErrorMessage = "به اینترنت وصل نیستید. لطفاً اتصال خود را بررسی کنید"
            showPostingError = true
            return
        }
        
        // Double-check after brief delay to ensure connection is stable
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        let hasInternet2 = await checkInternetConnection()
        if !hasInternet2 {
            postingErrorMessage = "به اینترنت وصل نیستید. لطفاً اتصال خود را بررسی کنید"
            showPostingError = true
            return
        }
        
        guard let url = URL(string: "https://myshop-backend-an7h.onrender.com/accounts/customer/addresses/") else {
            postingErrorMessage = "آدرس نامعتبر"
            showPostingError = true
            return
        }
        
        // Create URLSession with 15-second timeout (non-critical operations should be fast)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 15.0
        let session = URLSession(configuration: config)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15.0
        
        let addressCredentials = Address(
            label: address.label,
            receiver_name: address.receiver_name,
            country: "ایران",
            state: address.state,
            city: address.city,
            street_address: address.street_address,
            unit: address.unit,
            postal_code: address.postal_code,
            phone: address.phone
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(addressCredentials)
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                postingErrorMessage = NetworkError.invalidResponse.localizedMessage
                showPostingError = true
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
                print("Response Status: \(httpResponse.statusCode)")
            }
            
            // Handle HTTP status codes using enum
            if let error = NetworkError.from(httpStatusCode: httpResponse.statusCode) {
                postingErrorMessage = error.localizedMessage
                showPostingError = true
                return
            }
            
            // Handle success (201 = created, 200 = already exists - idempotent)
            // Server now checks for duplicates and returns existing address if found
            if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
                do {
                    let addressResponse = try JSONDecoder().decode(AddressResponse.self, from: data)
                    print(addressResponse.detail)
                    isAddressSaved = true
                } catch {
                    postingErrorMessage = "خطا در پردازش پاسخ سرور"
                    showPostingError = true
                }
            }
        } catch {
            // Handle network errors using the enum-based system
            handleNetworkErrorForUI(error, errorMessage: &postingErrorMessage, showError: &showPostingError)
        }
    }
    
    // Helper function to check internet connectivity
    private func checkInternetConnection() async -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        return await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                // Check if path is satisfied AND has a usable interface (WiFi or cellular, not just loopback)
                if path.status == .satisfied && (path.usesInterfaceType(.wifi) || path.usesInterfaceType(.cellular)) {
                    // Has internet connection (WiFi or cellular)
                    continuation.resume(returning: true)
                } else {
                    // No internet connection (no interface or interface not satisfied)
                    continuation.resume(returning: false)
                }
                monitor.cancel()
            }
            monitor.start(queue: queue)
        }
    }
}

// MARK: - UI Usage Example
/*
// In your AddressDetailView or form view:

ZStack {
    // Your form content here
    
    if viewModel.isPosting {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("در حال ذخیره...")
                .foregroundColor(.white)
                .font(.headline)
        }
        .padding(30)
        .background(Color.gray.opacity(0.9))
        .cornerRadius(15)
    }
}
.alert("خطا", isPresented: $viewModel.showPostingError) {
    Button("باشه", role: .cancel) {
        viewModel.postingErrorMessage = nil
    }
} message: {
    Text(viewModel.postingErrorMessage ?? "خطای نامشخص")
}

// Save button (no cancellation - operation should be fast):
Button {
    Task {
        await viewModel.postAddress(address: address)
    }
} label: {
    if viewModel.isPosting {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("در حال ذخیره...")
        }
    } else {
        Text("ذخیره آدرس")
    }
}
.disabled(viewModel.isPosting)
*/

