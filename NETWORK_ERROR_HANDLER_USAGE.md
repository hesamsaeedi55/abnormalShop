# Network Error Handler - Usage Guide

## Overview

The `NetworkErrorHandler.swift` file provides a reusable, enum-based error handling system for network operations. This eliminates code duplication and makes error handling consistent across your app.

## Structure

### 1. **NetworkError Enum**
Defines all possible network error types:
- `.noInternet` - No internet connection
- `.timeout` - Request timed out
- `.authenticationRequired` - User needs to login
- `.serverUnreachable` - Server cannot be reached
- `.invalidResponse` - Invalid response from server
- `.serverError(Int)` - Server returned error status code
- `.unknown(String)` - Unknown error

### 2. **Helper Functions**
- `NetworkError.from(_:)` - Convert URLError to NetworkError enum
- `NetworkError.from(httpStatusCode:)` - Convert HTTP status code to NetworkError
- `handleNetworkError(_:domain:)` - For async throws functions
- `handleNetworkErrorForUI(_:errorMessage:showError:)` - For async functions with Published properties
- `handleHTTPResponse(_:domain:)` - Handle HTTP response status codes

## Usage Examples

### For async throws functions (like deleteAddress):

```swift
do {
    let (_, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse.toNSError(domain: "AddressError")
    }
    
    // Handle HTTP status codes
    try handleHTTPResponse(httpResponse, domain: "AddressError")
    
    // Success - continue with operation
    if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
        // Success handling
    }
} catch {
    // Handle network errors using the enum-based system
    try handleNetworkError(error, domain: "AddressError")
}
```

### For async functions with Published properties (like postAddress):

```swift
do {
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        postingErrorMessage = NetworkError.invalidResponse.localizedMessage
        showPostingError = true
        return
    }
    
    // Handle HTTP status codes
    if let error = NetworkError.from(httpStatusCode: httpResponse.statusCode) {
        postingErrorMessage = error.localizedMessage
        showPostingError = true
        return
    }
    
    // Success handling
} catch {
    // Handle network errors using the enum-based system
    handleNetworkErrorForUI(error, errorMessage: &postingErrorMessage, showError: &showPostingError)
}
```

## Benefits

1. **Code Reusability** - Use the same error handling across all network functions
2. **Consistency** - All errors use the same messages and codes
3. **Maintainability** - Change error messages in one place
4. **Type Safety** - Enum-based system prevents typos and errors
5. **Clean Code** - No more long if-else chains

## Adding to Your Project

1. **Add `NetworkErrorHandler.swift`** to your project
2. **Import it** in files that need it (or add to AddressViewModel)
3. **Replace error handling** in your network functions with the new system

## Customization

To customize error messages, edit the `localizedMessage` property in the `NetworkError` enum:

```swift
var localizedMessage: String {
    switch self {
    case .noInternet:
        return "Your custom message here"
    // ... other cases
    }
}
```

## Example: Using in Other Functions

```swift
func loadAddresses() async throws {
    // ... network request code ...
    
    do {
        let (data, response) = try await session.data(for: request)
        try handleHTTPResponse(response as? HTTPURLResponse, domain: "AddressError")
        // Process data...
    } catch {
        try handleNetworkError(error, domain: "AddressError")
    }
}
```

