# Quick Fix for deleteFromBasket

## Issues:
1. **204 status = empty body** - Don't decode JSON when status is 204
2. **Syntax error** - Remove the `?` at the end

## Fixed Code:

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
        
        // Handle 204 (No Content) - empty body
        if httpResponse.statusCode == 204 {
            let successResponse = deleteResponse(success: true, message: "Deleted")
            Task { await loadShoppingBasket() }
            return successResponse
        }
        
        // Handle 200 (OK) - has response body
        if httpResponse.statusCode == 200 {
            let removeResponse = try JSONDecoder().decode(deleteResponse.self, from: data)
            print("product removed from basket: \(removeResponse)")
            Task { await loadShoppingBasket() }
            return removeResponse
        }
        
        throw HandlingError.httpError(httpResponse.statusCode)
    } catch {
        print(error)
        throw HandlingError.networkError(error)
    }
}
```

## Key Changes:
1. **Separate 204 and 200 handling** - Don't decode on 204
2. **Removed `?`** at end

