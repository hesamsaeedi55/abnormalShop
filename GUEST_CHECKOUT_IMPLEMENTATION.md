# Guest Checkout Implementation Guide

## ✅ Completed Steps

### Backend Changes

1. **Cart Model Updated** (`myshop2/myshop/shop/models.py`)
   - Added `session_key` field to support anonymous users
   - Made `customer` field nullable
   - Added `unique_together` constraint for `[customer, session_key]`

2. **Utility Function Created** (`myshop2/myshop/shop/views.py`)
   - `get_or_create_cart(request)` function handles both authenticated and guest users
   - Extracts device ID from `X-Device-ID` header for guests
   - Returns cart and authentication status

3. **Cart API Endpoints Updated** (`myshop2/myshop/shop/views.py`)
   - Removed `@login_required` decorator from `api_customer_cart`
   - GET, POST, PUT, DELETE methods now work for guests
   - All endpoints use `get_or_create_cart()` utility

4. **Checkout Endpoint Updated** (`myshop2/myshop/shop/views.py`)
   - Removed `@login_required` decorator
   - Supports guest checkout with email collection
   - Order model already supports guests (no customer field required)

### iOS Changes

1. **Device ID Generation** (`CustomerEcommerceApp.swift`)
   - Added device ID property to `APIManager`
   - Uses `UIDevice.current.identifierForVendor` or generates UUID
   - Persists in UserDefaults

2. **APIManager Updated** (`CustomerEcommerceApp.swift`)
   - Always sends `X-Device-ID` header in all requests
   - Works for both authenticated and guest users

3. **CartManager Updated** (`CustomerEcommerceApp.swift`)
   - Removed authentication check from `loadCart()`
   - Works for guests (device ID sent automatically)

## 🔧 Next Steps Required

### 1. Database Migration (CRITICAL)

You need to create and run a migration for the Cart model changes:

```bash
cd myshop2/myshop
python manage.py makemigrations shop
python manage.py migrate
```

The migration should:
- Add `session_key` field (CharField, max_length=100, blank=True)
- Make `customer` field nullable (null=True, blank=True)
- Add `unique_together` constraint

### 2. Update Checkout UI (iOS)

Update your checkout view to collect email for guest users:

```swift
// In your CheckoutView
@State private var email: String = ""
@State private var firstName: String = ""
@State private var lastName: String = ""

// Show email field if not authenticated
if !authManager.isAuthenticated {
    TextField("Email", text: $email)
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
    
    TextField("First Name", text: $firstName)
    TextField("Last Name", text: $lastName)
}
```

### 3. Update Checkout Request (iOS)

When submitting checkout, include email for guests:

```swift
var checkoutData: [String: Any] = [
    "delivery_option": deliveryOption,
    "payment_method": paymentMethod,
    "street_address": address,
    "city": city,
    "phone": phone,
    // ... other fields
]

// Add email if guest user
if !authManager.isAuthenticated {
    checkoutData["email"] = email
    checkoutData["first_name"] = firstName
    checkoutData["last_name"] = lastName
}
```

### 4. Test Guest Flow

1. **Test without authentication:**
   - Open app without logging in
   - Add items to cart
   - Verify cart persists
   - Complete checkout with email

2. **Test cart persistence:**
   - Add items as guest
   - Close and reopen app
   - Verify cart still exists

3. **Test login conversion:**
   - Add items as guest
   - Log in
   - Verify cart transfers to authenticated user

## 📋 API Endpoints Summary

### Cart Endpoints (Now Support Guests)

- `GET /shop/api/customer/cart/` - Get cart (requires `X-Device-ID` header for guests)
- `POST /shop/api/customer/cart/` - Add item (requires `X-Device-ID` header for guests)
- `PUT /shop/api/customer/cart/` - Update item quantity
- `DELETE /shop/api/customer/cart/` - Remove item

### Checkout Endpoint (Now Supports Guests)

- `POST /shop/api/customer/checkout/` - Create order
  - **For guests:** Requires `email`, `first_name`, `last_name`, `street_address`, `city`, `phone` in request body
  - **For authenticated:** Can use `address_id` or provide address details

## 🔍 How It Works

1. **Guest User Flow:**
   - iOS app generates device ID on first launch
   - Device ID stored in UserDefaults (persists across launches)
   - All API requests include `X-Device-ID` header
   - Backend creates cart with `customer=None, session_key=device_id`
   - Cart persists across app sessions

2. **Authenticated User Flow:**
   - User logs in, JWT token stored
   - API requests include `Authorization: Bearer <token>` header
   - Backend creates cart with `customer=user, session_key=''`
   - Works as before

3. **Checkout:**
   - Guest: Must provide email and address details
   - Authenticated: Can use saved address or provide new one
   - Order created without customer field (guest orders)

## ⚠️ Important Notes

1. **Migration Required:** The Cart model changes need a database migration
2. **Email Required:** Guest checkout requires email address
3. **Device ID:** Must be sent in `X-Device-ID` header for all cart operations
4. **Order Model:** Already supports guests (no changes needed)

## 🎯 Testing Checklist

- [ ] Run database migration
- [ ] Test guest cart (add items without login)
- [ ] Test cart persistence (close/reopen app)
- [ ] Test guest checkout with email
- [ ] Test authenticated cart still works
- [ ] Test login converts guest cart to user cart

