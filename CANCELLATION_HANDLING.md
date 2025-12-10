# Handling Client Cancellation During Server Processing

## The Problem

**Scenario:**
1. User clicks "Add to Cart" 
2. Request sent to server
3. Server starts processing (slow database, network delay)
4. User cancels on client side (`Task.cancel()`)
5. **Server continues processing and completes operation anyway**
6. Item appears in cart even though user cancelled

**Why this happens:**
- HTTP doesn't have reliable client cancellation detection
- Server doesn't know client disconnected
- Server continues processing the request

## Solutions by Operation Type

### ✅ **Safe Operations (Accept Completion After Cancel)**

These operations are **harmless** if they complete after cancellation:

#### 1. **Add to Cart** ✅
**Current behavior:** Uses `get_or_create()` - already safe
```python
cart_item, created = CartItem.objects.get_or_create(...)
if not created:
    cart_item.quantity += quantity  # Just updates quantity
```

**Why it's safe:**
- If item already in cart → just updates quantity (harmless)
- If item not in cart → adds it (user can remove it)
- User can easily remove unwanted items

**Recommendation:** ✅ **Accept it** - No changes needed

#### 2. **Add to Wishlist** ✅
**Current behavior:** Uses `get_or_create()` - already safe
```python
wishlist_item, created = Wishlist.objects.get_or_create(...)
```

**Why it's safe:**
- If already in wishlist → does nothing (idempotent)
- If not in wishlist → adds it (user can remove it)

**Recommendation:** ✅ **Accept it** - No changes needed

#### 3. **Add Address** ✅
**Current behavior:** Now has idempotency check

**Why it's safe:**
- If address exists → returns existing (no duplicate)
- If address doesn't exist → creates it (user can delete it)

**Recommendation:** ✅ **Accept it** - Already handled

### ⚠️ **Operations That Need Protection**

#### 1. **Create Order / Checkout** ⚠️ **CRITICAL**

**Problem:** If user cancels but order is created, they might be charged!

**Solutions:**

**Option A: Use Transaction with Rollback Detection**
```python
def post(self, request):
    from django.db import transaction
    
    with transaction.atomic():
        # Check if client disconnected (best effort)
        if request.META.get('HTTP_CONNECTION') == 'close':
            # Client disconnected, but we can't reliably detect this
            pass
        
        # Create order
        order = Order.objects.create(...)
        
        # If we can detect cancellation, rollback
        # But HTTP doesn't support this reliably
```

**Option B: Two-Phase Commit (Recommended)**
```python
# Phase 1: Create order in "pending" state
order = Order.objects.create(status='pending', ...)

# Phase 2: Confirm order (separate endpoint)
# Only charge/fulfill after confirmation
```

**Option C: Use Idempotency Key**
```python
# Client sends unique idempotency key
idempotency_key = request.data.get('idempotency_key')

# Check if order with this key already exists
existing = Order.objects.filter(idempotency_key=idempotency_key).first()
if existing:
    return Response({'order_id': existing.id}, status=200)

# Create new order
order = Order.objects.create(idempotency_key=idempotency_key, ...)
```

**Recommendation:** Use **Option C (Idempotency Key)** for orders

#### 2. **Payment Processing** ⚠️ **CRITICAL**

**Problem:** If user cancels but payment processes, they're charged!

**Solution:** Use payment gateway idempotency keys
```python
# Payment gateways (Stripe, PayPal) support idempotency keys
# They prevent duplicate charges even if request is retried
```

**Recommendation:** Always use payment gateway idempotency keys

### 🔧 **Technical Solutions**

#### Solution 1: Make Operations Fast (Best Practice)
- Optimize database queries
- Use caching
- Minimize processing time
- Less time = less chance of cancellation during processing

#### Solution 2: Optimistic UI Updates
```swift
// Client-side: Show item immediately
cartItems.append(item)

// Server: If request fails, rollback UI
Task {
    do {
        try await addToCart(item)
        // Success - item already shown
    } catch {
        // Failed - remove from UI
        cartItems.remove(item)
    }
}
```

#### Solution 3: Server-Side Cancellation Tokens (Complex)
- Requires WebSockets or Server-Sent Events
- Client sends cancellation signal
- Server checks cancellation before committing
- **Not practical for simple HTTP APIs**

## Recommendations by Operation

| Operation | Accept After Cancel? | Why |
|-----------|---------------------|-----|
| Add to Cart | ✅ Yes | Uses `get_or_create()`, user can remove |
| Add to Wishlist | ✅ Yes | Uses `get_or_create()`, user can remove |
| Add Address | ✅ Yes | Has idempotency, user can delete |
| Create Order | ❌ **NO** | Use idempotency key or two-phase commit |
| Process Payment | ❌ **NO** | Use payment gateway idempotency |
| Delete Item | ✅ Yes | Deleting twice is same as once |
| Update Profile | ✅ Yes | Update is idempotent |

## Implementation for Critical Operations

### Add Idempotency Key to Orders

**Client-side (Swift):**
```swift
func checkout() async {
    let idempotencyKey = UUID().uuidString
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
    // ... rest of request
}
```

**Server-side (Django):**
```python
def post(self, request):
    idempotency_key = request.headers.get('Idempotency-Key')
    
    if idempotency_key:
        existing = Order.objects.filter(idempotency_key=idempotency_key).first()
        if existing:
            return Response({
                'order_id': existing.id,
                'already_exists': True
            }, status=200)
    
    order = Order.objects.create(
        idempotency_key=idempotency_key,
        ...
    )
    return Response({...}, status=201)
```

## Summary

**For most operations (Cart, Wishlist, Address):**
- ✅ **Accept completion after cancel** - Operations are safe/harmless
- ✅ **User can undo** - They can remove/delete if unwanted

**For critical operations (Orders, Payments):**
- ❌ **Must prevent duplicate completion**
- ✅ **Use idempotency keys** - Prevents duplicates even if request completes after cancel
- ✅ **Use two-phase commits** - Only finalize after confirmation

**Best practice:**
- Make operations fast (less time to cancel)
- Use idempotency for critical operations
- Accept harmless operations completing after cancel

