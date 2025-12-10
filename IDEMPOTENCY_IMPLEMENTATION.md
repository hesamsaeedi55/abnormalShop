# Idempotency Implementation for Address Creation

## Problem
Without idempotency, duplicate addresses could be created when:
- User cancels a request and retries
- Network issues cause automatic retries
- User accidentally submits the form twice
- Request times out and user retries

## Solution: Duplicate Detection

### Server-Side (Django)
The `CustomerAddressesListView.post()` method now:

1. **Checks for existing identical address** before creating
2. **Returns existing address** if found (status 200)
3. **Creates new address** only if it doesn't exist (status 201)

### How It Works

```python
# Check if identical address already exists
existing_address = Address.objects.filter(
    customer=customer,
    receiver_name=address_data['receiver_name'],
    street_address=address_data['street_address'],
    city=address_data['city'],
    province=address_data['province'],
    vahed=address_data['vahed'],
    phone=address_data['phone'],
    country=address_data['country'],
    postal_code=address_data['postal_code'],
).first()

if existing_address:
    # Return existing address (idempotent)
    return Response({
        'detail': 'Address already exists.',
        'address_id': existing_address.id,
        'already_exists': True
    }, status=200)
else:
    # Create new address
    address = Address.objects.create(...)
    return Response({...}, status=201)
```

### Client-Side (Swift)
The Swift client handles both status codes:
- **200**: Address already existed (idempotent - no duplicate created)
- **201**: New address was created

## Benefits

✅ **No duplicates** - Identical addresses are detected and reused
✅ **Safe retries** - User can retry without creating duplicates
✅ **Safe cancellations** - Cancelling and retrying won't create duplicates
✅ **Network resilient** - Automatic retries won't create duplicates
✅ **User-friendly** - Users can submit multiple times without issues

## Test Scenarios

### Scenario 1: User Cancels and Retries
1. User submits address
2. User cancels after 10 seconds
3. User submits same address again
4. **Result**: Server returns existing address (200), no duplicate created ✅

### Scenario 2: Network Retry
1. User submits address
2. Network request succeeds but response is lost
3. Client retries automatically
4. **Result**: Server returns existing address (200), no duplicate created ✅

### Scenario 3: Double Submit
1. User accidentally taps "Save" twice quickly
2. Two requests sent simultaneously
3. **Result**: First creates address (201), second returns existing (200), no duplicate ✅

### Scenario 4: Different Address
1. User submits address A
2. User submits address B (different details)
3. **Result**: Both addresses created normally ✅

## Important Notes

- **Label is not checked** - Only address fields are compared (label can be different)
- **Exact match required** - All fields must match exactly to be considered duplicate
- **Per-customer** - Duplicate check is scoped to the same customer

## Files Modified

1. `myshop2/myshop/accounts/views.py` - Added duplicate detection in `post()` method
2. `postAddress_FIXED.swift` - Updated comments to explain idempotent behavior

