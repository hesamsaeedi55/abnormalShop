// FIXED VERSION - Simplified deleteAddress for non-critical operations
// 15-second timeout, no cancellation - operations should be fast
// Improved error handling to detect "no internet" when WiFi is off
// Uses NetworkErrorHandler for consistent error handling
// Add this to your AddressViewModel class
// Requires: import Network, NetworkErrorHandler.swift

import Network

func deleteaddress(address: Address) async throws {
    // Prevent concurrent delete operations
    guard !isDeleting else { return }
    
    isDeleting = true
    defer { isDeleting = false }  // Always reset, even on error
    
    // Check internet connectivity first (more reliable than error parsing)
    // Check twice with small delay to ensure stable connection (not just momentary)
    let hasInternet1 = await checkInternetConnection()
    if !hasInternet1 {
        throw NSError(domain: "AddressError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "به اینترنت وصل نیستید. لطفاً اتصال خود را بررسی کنید"])
    }
    
    // Double-check after brief delay to ensure connection is stable
    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    let hasInternet2 = await checkInternetConnection()
    if !hasInternet2 {
        throw NSError(domain: "AddressError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "به اینترنت وصل نیستید. لطفاً اتصال خود را بررسی کنید"])
    }
    
    guard let id = address.id else {
        throw NSError(domain: "AddressError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Address ID is missing"])
    }
    
    guard let url = URL(string: "https://myshop-backend-an7h.onrender.com/accounts/customer/addresses/\(id)/") else {
        throw NSError(domain: "AddressError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
    }
    
    // Create URLSession with 15-second timeout (non-critical operations should be fast)
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 15.0
    config.timeoutIntervalForResource = 15.0
    let session = URLSession(configuration: config)
    
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "")", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 15.0  // Must match config timeout
    
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse.toNSError(domain: "AddressError")
            }
            
            // Handle HTTP status codes
            try handleHTTPResponse(httpResponse, domain: "AddressError")
            
            // Success - reload addresses
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                try await loadAddress()
            }
        } catch {
            // Handle network errors using the enum-based system
            try handleNetworkError(error, domain: "AddressError")
        }
}

// Helper function to check internet connectivity
// NOTE: Add this ONCE to your AddressViewModel class (both postAddress and deleteAddress can use it)
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

