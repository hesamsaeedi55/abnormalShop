# Simplified Timeout Policy for Non-Critical Operations

## Decision: **15-Second Timeout, No Cancellation**

## Rationale

For non-critical operations (cart, wishlist, address), users shouldn't need to wait long:
- ✅ **Fast operations** (< 5 seconds normally)
- ✅ **If > 15 seconds** = something is wrong (show error)
- ✅ **No cancellation needed** = simpler code, simpler UX
- ✅ **Users can retry** if timeout occurs

## Implementation

### Timeout: **15 seconds** (reduced from 30)
- Non-critical operations should be fast
- If it takes > 15 seconds, it's likely an error
- Faster error feedback for users

### No Cancellation Support
- Removed `currentPostTask` storage
- Removed `cancelButtonTimer`
- Removed `showCancelButton` property
- Removed `cancelPosting()` function
- Removed cancellation error handling

### Simplified Code
- Direct async/await (no Task wrapper)
- Cleaner error handling
- Less code to maintain

## Updated Code Structure

```swift
func postAddress(address: Address) async {
    guard !isPosting else { return }
    
    isPosting = true
    defer { isPosting = false }
    
    // 15-second timeout
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 15.0
    config.timeoutIntervalForResource = 15.0
    
    // Direct network call (no Task wrapper)
    do {
        let (data, response) = try await session.data(for: request)
        // Handle response...
    } catch {
        // Handle errors (timeout, network, etc.)
    }
}
```

## UI Changes

### Before (with cancellation):
```swift
if viewModel.showCancelButton {
    Button("لغو") {
        viewModel.cancelPosting()
    }
}
```

### After (no cancellation):
```swift
// Just show loading indicator
if viewModel.isPosting {
    ProgressView()
    Text("در حال ذخیره...")
}
// No cancel button
```

## Benefits

1. **Simpler Code**
   - Less code to maintain
   - No cancellation logic
   - No Task storage

2. **Better UX**
   - Clear loading state
   - Fast timeout (15s) = faster error feedback
   - Users can retry if needed

3. **Appropriate for Non-Critical Operations**
   - Operations should be fast anyway
   - If slow, it's an error (show error, allow retry)
   - No need for complex cancellation handling

## Operations Using This Pattern

- ✅ **Add Address** - 15s timeout, no cancellation
- ✅ **Delete Address** - 15s timeout, no cancellation
- ✅ **Add to Cart** - 15s timeout, no cancellation (if implemented)
- ✅ **Add to Wishlist** - 15s timeout, no cancellation (if implemented)

## Critical Operations (Different Pattern)

For critical operations (checkout, payment):
- **30-second timeout** (operations may take longer)
- **No cancellation** (user already confirmed)
- **Show confirmation first** (then lock UI)

## Summary

**For non-critical operations:**
- ✅ 15-second timeout
- ✅ No cancellation support
- ✅ Simple, clean code
- ✅ Fast error feedback

**Why this works:**
- Operations should be fast (< 5s normally)
- If > 15s, it's an error (show error, allow retry)
- No need for cancellation complexity
- Better UX (clear loading, fast feedback)

