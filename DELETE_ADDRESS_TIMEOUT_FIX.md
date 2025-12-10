# Delete Address Timeout Handling - Issues Fixed

## Issues Found in Your Code

### ❌ **Issue 1: Inconsistent Timeout**
**Problem:**
```swift
config.timeoutIntervalForRequest = 15.0  // Config says 15s
request.timeoutInterval = 30.0          // But request says 30s!
```

**Why this is bad:**
- `request.timeoutInterval` **overrides** the config
- Actual timeout is 30 seconds, not 15
- Inconsistent with your postAddress function (15s)
- Confusing for maintenance

**Fix:**
```swift
config.timeoutIntervalForRequest = 15.0
request.timeoutInterval = 15.0  // Must match config
```

### ❌ **Issue 2: Wrong Timeout Message**
**Problem:**
```swift
"Request timed out after 30 seconds"  // Says 30s but should be 15s
```

**Fix:**
```swift
"بیش از ۱۵ ثانیه طول کشید. لطفاً دوباره امتحان کنید"
```

### ✅ **Issue 3: Missing Error Cases**
**Your code had:** `.userAuthenticationRequired` handling
**File was missing:** This error case

**Fix:** Added authentication error handling

### ✅ **Issue 4: Missing Server Unreachable Error**
**Problem:** No handling for `.cannotConnectToHost` or `.cannotFindHost`

**Fix:** Added server unreachable error handling

## Fixed Code

### Timeout Configuration (Now Consistent)
```swift
// Create URLSession with 15-second timeout
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 15.0
config.timeoutIntervalForResource = 15.0
let session = URLSession(configuration: config)

var request = URLRequest(url: url)
request.timeoutInterval = 15.0  // ✅ Matches config
```

### Error Handling (Complete)
```swift
catch let error as URLError {
    if error.code == .timedOut {
        // ✅ Correct timeout message (15 seconds)
        throw NSError(..., userInfo: [NSLocalizedDescriptionKey: "بیش از ۱۵ ثانیه طول کشید..."])
    } else if error.code == .userAuthenticationRequired {
        // ✅ Added authentication error
        throw NSError(..., userInfo: [NSLocalizedDescriptionKey: "ابتدا وارد حساب کاربری خود شوید"])
    } else if error.code == .notConnectedToInternet {
        // ✅ Internet connection error
        throw NSError(..., userInfo: [NSLocalizedDescriptionKey: "به اینترنت وصل نیستید..."])
    } else if error.code == .cannotConnectToHost || error.code == .cannotFindHost {
        // ✅ Added server unreachable error
        throw NSError(..., userInfo: [NSLocalizedDescriptionKey: "سرور در دسترس نیست..."])
    } else {
        // ✅ Generic network error
        throw NSError(..., userInfo: [NSLocalizedDescriptionKey: "خطای شبکه: ..."])
    }
}
```

## Summary

**Before:**
- ❌ Inconsistent timeout (15s config, 30s request)
- ❌ Wrong timeout message (said 30s)
- ⚠️ Missing some error cases

**After:**
- ✅ Consistent 15-second timeout
- ✅ Correct timeout message
- ✅ Complete error handling
- ✅ Matches postAddress pattern

## Does It Handle Timeout Well Now?

**Yes!** ✅

1. **Consistent timeout:** 15 seconds (matches postAddress)
2. **Clear error message:** Tells user it took > 15 seconds
3. **Complete error handling:** All network errors covered
4. **User-friendly:** Persian error messages
5. **Matches pattern:** Same as postAddress function

## Note About Hardcoded Token

**Security Issue Found:**
```swift
UserDefaults.standard.string(forKey: "accessToken") ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Recommendation:** Remove hardcoded fallback token - it's a security risk. If token is missing, show login screen instead.

