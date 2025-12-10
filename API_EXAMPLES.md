# Order API Examples

## 1. Submit Order (Checkout)
```http
POST /api/checkout/
Authorization: Bearer <token>

{
  "address_id": 1,  // OR provide full address:
  // "receiver_name": "John Doe",
  // "street_address": "123 Main St",
  // "city": "Tehran",
  // "province": "Tehran",
  // "phone": "09123456789",
  // "country": "Iran",
  // "postal_code": "1234567890",
  // "unit": "5",
  // "address_label": "Home",
  "delivery_option": "standard",
  "payment_method": "cod",
  "discount_code": "",
  "delivery_notes": "Please ring doorbell"
}
```

## 2. Return Full Order
```http
POST /api/orders/123/return/

{
  "return_type": "full",
  "reason": "Product damaged",
  "customer_notes": "Box was crushed"
}
```

## 3. Return Specific Item
```http
POST /api/orders/123/items/456/return/

{
  "quantity": 1,
  "reason": "Wrong size"
}
```

## 4. Reject Order
```http
POST /api/orders/123/reject/

{
  "reason": "Not satisfied with quality"
}
```

## 5. Reject Specific Item
```http
POST /api/orders/123/items/456/reject/

{
  "quantity": 2,
  "reason": "Defective product"
}
```

## 6. List Returns
```http
GET /api/orders/returns/
```

## 7. Get Order Details
```http
GET /api/orders/123/
```


