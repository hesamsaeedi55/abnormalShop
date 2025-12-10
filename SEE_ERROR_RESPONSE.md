# How to See Error Response Body

## Current Problem
You're only seeing HTTP headers, but not the JSON error message from the response body.

## Solution: Print Response Body on Error

```swift
func deleteFromBasket(itemId: Int) async throws -> deleteResponse {
    guard !isLoading else { throw HandlingError.alreadyLoading }
    
    let urlString = "http://127.0.0.1:8000/shop/api/customer/cart/remove/"
    
    var request = URLRequest(url: URL(string: urlString)!)
    request.setValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYyMDk2ODEyLCJpYXQiOjE3NjIwMTA0MTIsImp0aSI6ImMzNTYwZWUzZjgxNTRhOWJhZDM5NmZjNmI0OTg5ZjczIiwidXNlcl9pZCI6MzB9.0jdsCoQesgI4bFlI4VJhhlN3izQomBqAp24innEZI1E")", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "DELETE"
    
    let body = ["item_id": itemId]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        print(response)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HandlingError.invalidResponse
        }
        
        // ✅ ADD THIS: Always print response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            let removeResponse = try JSONDecoder().decode(deleteResponse.self, from: data)
            print("product removed from basket: \(removeResponse)")
            Task { await loadShoppingBasket() }
            return removeResponse
        } else {
            // ✅ ADD THIS: Print error details when status code is not 200
            print("❌ HTTP Status: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error response: \(errorString)")
            }
            
            // Try to decode error response
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                print("❌ Error message: \(errorMessage)")
            }
            
            throw HandlingError.httpError(httpResponse.statusCode)
        }
    } catch {
        print(error)
        throw HandlingError.networkError(error)
    }
}
```

## Better: Decode Error Response Struct

Create an error response struct:

```swift
struct ErrorResponse: Codable {
    let error: String
}

// Then in your function:
if httpResponse.statusCode == 200 {
    // ... success handling
} else {
    // Decode error response
    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
        print("❌ Error: \(errorResponse.error)")
    }
    
    // Also print raw response
    if let errorString = String(data: data, encoding: .utf8) {
        print("❌ Raw error: \(errorString)")
    }
    
    throw HandlingError.httpError(httpResponse.statusCode)
}
```

## Simplest Version

Just add these two lines after getting the response:

```swift
let (data, response) = try await URLSession.shared.data(for: request)
print(response)

// ✅ ADD THESE LINES:
if let responseString = String(data: data, encoding: .utf8) {
    print("Response body: \(responseString)")
}

guard let httpResponse = response as? HTTPURLResponse else {
    throw HandlingError.invalidResponse
}
```

