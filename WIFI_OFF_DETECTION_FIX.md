# Fix: Detecting "No Internet" When WiFi is Off

## The Problem

When WiFi is turned off on iPhone:
- iOS might return `.timedOut` instead of `.notConnectedToInternet`
- User sees "Timeout" message instead of "Check your internet connection"
- This happens because iOS waits for the full timeout period before reporting the error

## Why This Happens

1. **WiFi off, Cellular on:** Usually works (uses cellular)
2. **WiFi off, Cellular off:** iOS waits for timeout, then returns `.timedOut`
3. **WiFi off, Cellular slow:** Might timeout before detecting no internet

## The Fix Applied

### 1. **Reordered Error Checks**
Check `.notConnectedToInternet` FIRST (before timeout)

### 2. **Treat Host Unreachable as No Internet**
```swift
else if error.code == .cannotConnectToHost || error.code == .cannotFindHost {
    // Host unreachable often means no internet (when WiFi is off)
    postingErrorMessage = "به اینترنت وصل نیستید..."
}
```

### 3. **Check Timeout Error Description**
```swift
else if error.code == .timedOut {
    let errorDesc = error.localizedDescription.lowercased()
    if errorDesc.contains("network") || errorDesc.contains("internet") || 
       errorDesc.contains("connection") || errorDesc.contains("unreachable") {
        // Treat as no internet
        postingErrorMessage = "به اینترنت وصل نیستید..."
    } else {
        // Real timeout (server slow)
        postingErrorMessage = "بیش از ۱۵ ثانیه طول کشید..."
    }
}
```

## Limitations

**Error description checking is not 100% reliable:**
- iOS error messages might not always contain "network" or "internet"
- Some timeouts are real server timeouts (not no internet)
- Hard to distinguish between "no internet timeout" and "slow server timeout"

## Better Solution (Optional): Use Network Framework

For more reliable detection, you can check connectivity before making the request:

```swift
import Network

func checkInternetConnection() async -> Bool {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "NetworkMonitor")
    
    return await withCheckedContinuation { continuation in
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                continuation.resume(returning: true)
            } else {
                continuation.resume(returning: false)
            }
            monitor.cancel()
        }
        monitor.start(queue: queue)
    }
}

func postAddress(address: Address) async {
    // Check connectivity first
    let hasInternet = await checkInternetConnection()
    if !hasInternet {
        postingErrorMessage = "به اینترنت وصل نیستید. لطفاً اتصال خود را بررسی کنید"
        showPostingError = true
        return
    }
    
    // Continue with request...
}
```

**Pros:**
- ✅ More reliable detection
- ✅ Immediate feedback (no waiting for timeout)
- ✅ Works even when WiFi is off

**Cons:**
- ⚠️ Requires Network framework import
- ⚠️ Adds complexity
- ⚠️ Slight performance overhead

## Current Solution (Applied)

**What we did:**
1. ✅ Check `.notConnectedToInternet` first
2. ✅ Treat `.cannotConnectToHost` as no internet
3. ✅ Check timeout error description for connectivity hints

**This should work in most cases:**
- When iOS properly reports `.notConnectedToInternet` → Shows "no internet" ✅
- When iOS reports `.cannotConnectToHost` → Shows "no internet" ✅
- When timeout error mentions connectivity → Shows "no internet" ✅
- When timeout is real server timeout → Shows "timeout" ✅

## Testing

**Test scenarios:**
1. Turn off WiFi (cellular on) → Should work or show appropriate error
2. Turn off WiFi (cellular off) → Should show "no internet" (not timeout)
3. Turn on WiFi but disconnect router → Should show "no internet" or "server unreachable"
4. Normal timeout (server slow) → Should show "timeout" message

## Summary

**Fixed:**
- ✅ Reordered error checks (no internet first)
- ✅ Treat host unreachable as no internet
- ✅ Check timeout error description for connectivity hints

**Result:**
- Should now show "به اینترنت وصل نیستید" when WiFi is off
- Instead of "بیش از ۱۵ ثانیه طول کشید"

**If it still shows timeout:**
- Consider using Network framework for more reliable detection
- Or accept that some cases are hard to distinguish

