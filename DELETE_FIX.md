# DELETE Request Fix

## Problem
You're getting **405 Method Not Allowed** because:
- Backend expects: `DELETE`
- Your code sends: `POST`

## Solution

Change this line:
```swift
request.httpMethod = "POST"  // ❌ Wrong
```

To:
```swift
request.httpMethod = "DELETE"  // ✅ Correct
```

## Fixed Code

```swift
func deleteFromBasket(itemId: Int) async throws -> deleteResponse {
    guard !isLoading else { throw HandlingError.alreadyLoading }
    
    let urlString = "http://127.0.0.1:8000/shop/api/customer/cart/remove/"
    
    var request = URLRequest(url: URL(string: urlString)!)
    request.setValue("Bearer \(UserDefaults.standard.string(forKey: "accessToken") ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzYyMDk2ODEyLCJpYXQiOjE3NjIwMTA0MTIsImp0aSI6ImMzNTYwZWUzZjgxNTRhOWJhZDM5NmZjNmI0OTg5ZjczIiwidXNlcl9pZCI6MzB9.0jdsCoQesgI4bFlI4VJhhlN3izQomBqAp24innEZI1E")", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "DELETE"  // ✅ FIX: Changed from "POST" to "DELETE"
    
    let body = ["item_id": itemId]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        print(response)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HandlingError.invalidResponse
        }
        
        if httpResponse.statusCode == 204 || httpResponse.statusCode == 200 {
            // Note: 204 No Content means empty body, handle that case
            if httpResponse.statusCode == 204 || data.isEmpty {
                // Create a success response manually for 204
                let successResponse = deleteResponse(success: true, message: "Item deleted successfully")
                Task {
                    await loadShoppingBasket()
                }
                return successResponse
            } else {
                let removeResponse = try JSONDecoder().decode(deleteResponse.self, from: data)
                print("product removed from basket: \(removeResponse)")
                print("\(removeResponse.success)")
                Task {
                    await loadShoppingBasket()
                }
                return removeResponse
            }
        } else {
            throw HandlingError.httpError(httpResponse.statusCode)
        }
    } catch {
        print(error)
        throw HandlingError.networkError(error)
    }
}
```

## Additional Notes

1. **DELETE requests can have a body**, which you're doing correctly
2. **Status code 204** means "No Content" (empty body) - you may need to handle this case
3. If you get 204, the body will be empty, so don't try to decode JSON

## Alternative: Handle 204 Response

If the backend returns 204 with no body, you can simplify:

```swift
if httpResponse.statusCode == 204 {
    // 204 No Content - success with empty body
    let successResponse = deleteResponse(success: true, message: "Item deleted")
    Task { await loadShoppingBasket() }
    return successResponse
} else if httpResponse.statusCode == 200 {
    // 200 OK - decode response body
    let removeResponse = try JSONDecoder().decode(deleteResponse.self, from: data)
    Task { await loadShoppingBasket() }
    return removeResponse
} else {
    throw HandlingError.httpError(httpResponse.statusCode)
}
```

