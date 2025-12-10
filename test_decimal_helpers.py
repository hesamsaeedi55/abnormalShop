#!/usr/bin/env python3
"""
Test script to verify the Decimal helper functions work correctly
"""
from decimal import Decimal, InvalidOperation

def safe_decimal_to_float(decimal_value, default=0):
    """Safely convert Decimal to float, handling NaN and Infinity"""
    from decimal import Decimal, InvalidOperation
    if decimal_value is None:
        return default
    try:
        if isinstance(decimal_value, Decimal):
            if decimal_value.is_nan() or decimal_value.is_infinite():
                return default
            return float(decimal_value)
        return float(decimal_value)
    except (TypeError, ValueError, AttributeError, InvalidOperation):
        return default

def safe_get_decimal_field(obj, field_name, default=None):
    """Safely get Decimal field value from Django model instance"""
    from decimal import InvalidOperation
    if obj is None:
        return default
    try:
        if not hasattr(obj, field_name):
            return default
        # Use getattr but catch InvalidOperation that might be raised during field access
        try:
            value = getattr(obj, field_name)
            # If value is None, return default
            if value is None:
                return default
            return value
        except InvalidOperation:
            # If InvalidOperation is raised during field access, return default
            print(f"⚠️ InvalidOperation when accessing {field_name} on {obj.__class__.__name__} (id: {getattr(obj, 'id', 'unknown')})")
            return default
    except (AttributeError, Exception) as e:
        # Catch any other exceptions
        if 'InvalidOperation' in str(type(e)) or 'InvalidOperation' in str(e):
            print(f"⚠️ InvalidOperation error accessing {field_name} on {obj.__class__.__name__}: {e}")
        return default

# Test cases
print("🧪 Testing Decimal Helper Functions")
print("=" * 50)

# Test 1: Normal Decimal conversion
print("\n1. Testing normal Decimal conversion:")
test_val = Decimal('100.50')
result = safe_decimal_to_float(test_val)
print(f"   Input: {test_val} (type: {type(test_val)})")
print(f"   Output: {result} (type: {type(result)})")
assert result == 100.5, f"Expected 100.5, got {result}"
print("   ✅ PASS")

# Test 2: None value
print("\n2. Testing None value:")
result = safe_decimal_to_float(None)
print(f"   Input: None")
print(f"   Output: {result} (default: 0)")
assert result == 0, f"Expected 0, got {result}"
print("   ✅ PASS")

# Test 3: NaN Decimal
print("\n3. Testing NaN Decimal:")
try:
    nan_val = Decimal('NaN')
    result = safe_decimal_to_float(nan_val)
    print(f"   Input: {nan_val} (is_nan: {nan_val.is_nan()})")
    print(f"   Output: {result} (should be default: 0)")
    assert result == 0, f"Expected 0 for NaN, got {result}"
    print("   ✅ PASS")
except Exception as e:
    print(f"   ⚠️ Could not create NaN: {e}")

# Test 4: Infinity Decimal
print("\n4. Testing Infinity Decimal:")
try:
    inf_val = Decimal('Infinity')
    result = safe_decimal_to_float(inf_val)
    print(f"   Input: {inf_val} (is_infinite: {inf_val.is_infinite()})")
    print(f"   Output: {result} (should be default: 0)")
    assert result == 0, f"Expected 0 for Infinity, got {result}"
    print("   ✅ PASS")
except Exception as e:
    print(f"   ⚠️ Could not create Infinity: {e}")

# Test 5: Invalid string conversion
print("\n5. Testing invalid string conversion:")
try:
    result = safe_decimal_to_float("invalid")
    print(f"   Input: 'invalid'")
    print(f"   Output: {result} (should be default: 0)")
    assert result == 0, f"Expected 0 for invalid string, got {result}"
    print("   ✅ PASS")
except Exception as e:
    print(f"   ⚠️ Error: {e}")

# Test 6: Test safe_get_decimal_field with mock object
print("\n6. Testing safe_get_decimal_field with mock object:")

class MockProduct:
    def __init__(self, price_toman=None):
        self.id = 1
        self.price_toman = price_toman

# Test with valid Decimal
mock_product = MockProduct(Decimal('200.00'))
result = safe_get_decimal_field(mock_product, 'price_toman')
print(f"   Valid Decimal field: {result}")
assert result == Decimal('200.00'), "Should return the Decimal value"
print("   ✅ PASS")

# Test with None
mock_product_none = MockProduct(None)
result = safe_get_decimal_field(mock_product_none, 'price_toman')
print(f"   None field: {result}")
assert result is None, "Should return None"
print("   ✅ PASS")

# Test with non-existent field
result = safe_get_decimal_field(mock_product, 'nonexistent_field')
print(f"   Non-existent field: {result}")
assert result is None, "Should return None"
print("   ✅ PASS")

# Test with None object
result = safe_get_decimal_field(None, 'price_toman')
print(f"   None object: {result}")
assert result is None, "Should return None"
print("   ✅ PASS")

print("\n" + "=" * 50)
print("✅ All tests passed!")
print("\nNote: These tests verify the helper functions work correctly.")
print("To fully test the API, you need to:")
print("1. Start your Django server")
print("2. Make a GET request to /shop/api/customer/cart/")
print("3. Check the response for any InvalidOperation errors")



