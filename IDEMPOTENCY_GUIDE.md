# Idempotency Guide: When to Add It

## Quick Answer: **NO, not all functions need idempotency**

## Categories of Operations

### ✅ **Already Idempotent (No Changes Needed)**

These HTTP methods are naturally idempotent:

1. **GET** - Reading data (always safe to retry)
2. **PUT** - Updating resources (updating twice = same result)
3. **DELETE** - Deleting resources (deleting twice = same result)

### ✅ **Already Using Idempotent Patterns**

These endpoints already use `get_or_create()` which is idempotent:

1. **Cart Add** (`CartView.post`) - Uses `get_or_create()` ✅
   ```python
   cart_item, created = CartItem.objects.get_or_create(...)
   ```

2. **Wishlist Add** (`WishlistView.post`) - Uses `get_or_create()` ✅
   ```python
   wishlist_item, created = Wishlist.objects.get_or_create(...)
   ```

### ✅ **Should Add Idempotency**

These create resources and could create duplicates:

1. **Address Creation** ✅ **DONE** - Already implemented
2. **Product Creation** - If same product submitted twice
3. **Variant Creation** - If same variant submitted twice
4. **Special Offer Creation** - If same offer submitted twice
5. **Category Creation** - If same category submitted twice

### ❌ **MUST NOT Be Idempotent**

These operations **must create new records** every time:

1. **Order/Checkout** (`CheckoutView.post`) ❌
   - **Why**: Each order must be unique (even with same items)
   - **Risk**: Duplicate orders = duplicate charges
   - **Solution**: Use unique order IDs or timestamps

2. **Payment Processing** ❌
   - **Why**: Each payment must be processed once
   - **Risk**: Duplicate payments = financial loss
   - **Solution**: Use payment gateway idempotency keys

3. **User Registration** (optional)
   - Usually not idempotent (email must be unique anyway)
   - But could check if user exists before creating

## Decision Matrix

| Operation | Needs Idempotency? | Reason |
|-----------|-------------------|---------|
| GET | ❌ No | Naturally idempotent |
| PUT | ❌ No | Naturally idempotent |
| DELETE | ❌ No | Naturally idempotent |
| Address POST | ✅ Yes | **DONE** - Prevents duplicate addresses |
| Cart Add POST | ✅ Already | Uses `get_or_create()` |
| Wishlist Add POST | ✅ Already | Uses `get_or_create()` |
| Order/Checkout POST | ❌ **NO** | Must create new order each time |
| Payment POST | ❌ **NO** | Must process each payment once |
| Product POST | ⚠️ Maybe | Depends on business logic |
| Variant POST | ⚠️ Maybe | Depends on business logic |

## Implementation Pattern

### For Resource Creation (Address, Product, etc.)

```python
def post(self, request):
    # 1. Prepare data
    data = {...}
    
    # 2. Check for existing identical resource
    existing = Model.objects.filter(
        field1=data['field1'],
        field2=data['field2'],
        # ... all identifying fields
    ).first()
    
    # 3. Return existing or create new
    if existing:
        return Response({
            'detail': 'Resource already exists',
            'id': existing.id,
            'already_exists': True
        }, status=200)
    
    # 4. Create new
    new_resource = Model.objects.create(**data)
    return Response({...}, status=201)
```

### For Operations That Must NOT Be Idempotent (Orders, Payments)

```python
def post(self, request):
    # Always create new - no duplicate check
    # Use unique identifiers (UUID, timestamp, etc.)
    order = Order.objects.create(
        order_number=generate_unique_order_number(),
        ...
    )
    return Response({...}, status=201)
```

## Recommendations

### High Priority (Add Idempotency)
1. ✅ **Address Creation** - DONE
2. ⚠️ **Product Creation** - If products can be duplicated
3. ⚠️ **Variant Creation** - If variants can be duplicated

### Medium Priority (Consider)
1. **Category Creation** - Usually not needed (categories are unique)
2. **Special Offer Creation** - Could prevent duplicate offers

### Low Priority (Not Needed)
1. **Cart Operations** - Already idempotent via `get_or_create()`
2. **Wishlist Operations** - Already idempotent via `get_or_create()`
3. **GET/PUT/DELETE** - Naturally idempotent

### Never Add (Critical)
1. ❌ **Order Creation** - Must create new order each time
2. ❌ **Payment Processing** - Must process each payment once

## Testing Idempotency

For each idempotent endpoint, test:

1. **First request** → Creates resource (201)
2. **Identical second request** → Returns existing (200)
3. **Different data** → Creates new resource (201)

## Summary

**Don't add idempotency to everything!**

- ✅ Add to: Resource creation that could be duplicated
- ❌ Don't add to: Orders, payments, or operations that must be unique
- ✅ Already have: Cart, wishlist (using `get_or_create()`)
- ❌ Naturally idempotent: GET, PUT, DELETE

**Rule of thumb**: If duplicate creation would cause problems, add idempotency. If each operation must be unique, don't add it.

