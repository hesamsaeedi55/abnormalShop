"""
Customer Platform API Views and Serializers
===========================================

This file contains all the API views and serializers for the customer-facing platform.
Add these to your existing shop/api_views.py or create a new customer app.

APIs included:
- Authentication (signup, login, password reset)
- Product browsing and search
- Cart management
- Wishlist functionality
- Checkout and payment
- Order management
- Product reviews
- Notifications
"""

from rest_framework import serializers, status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.pagination import PageNumberPagination
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.db.models import Q, Avg, Count
from django.utils import timezone
from django.conf import settings
import uuid
import json

from .models import (
    Product, ProductVariant, Category, Cart, CartItem, Wishlist, 
    Order, OrderItem, OrderReturn, OrderReturnItem, ProductReview, ReviewImage, CustomerNotification,
    PaymentMethod, DeliveryOption, Address
)

User = get_user_model()

# ========================================
# SERIALIZERS
# ========================================

class CustomerRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for customer registration"""
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = ['email', 'first_name', 'last_name', 'phone_number', 'password', 'password_confirm']
        extra_kwargs = {
            'email': {'required': True},
            'first_name': {'required': True},
            'last_name': {'required': True},
        }
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        return user


class CustomerLoginSerializer(serializers.Serializer):
    """Serializer for customer login"""
    email = serializers.EmailField()
    password = serializers.CharField()
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        
        if email and password:
            user = authenticate(username=email, password=password)
            if not user:
                raise serializers.ValidationError('Invalid credentials')
            if not user.is_active:
                raise serializers.ValidationError('Account is disabled')
            attrs['user'] = user
        else:
            raise serializers.ValidationError('Must include email and password')
        
        return attrs


class ProductVariantSerializer(serializers.ModelSerializer):
    """Serializer for product variants"""
    class Meta:
        model = ProductVariant
        fields = ['id', 'sku', 'variant_name', 'price_toman', 'price_usd', 'stock_quantity', 'is_active']


class ProductImageSerializer(serializers.ModelSerializer):
    """Serializer for product images"""
    class Meta:
        model = ProductImage  # Assuming you have this model
        fields = ['id', 'image', 'is_primary', 'display_order']


class ProductSerializer(serializers.ModelSerializer):
    """Serializer for products with variants and images"""
    variants = ProductVariantSerializer(many=True, read_only=True)
    images = ProductImageSerializer(many=True, read_only=True)
    average_rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()
    is_in_wishlist = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price_toman', 'price_usd',
            'category', 'supplier', 'is_active', 'created_at',
            'variants', 'images', 'average_rating', 'review_count', 'is_in_wishlist',
            'reduced_price_toman', 'discount_percentage'
        ]
    
    def get_average_rating(self, obj):
        return obj.reviews.filter(is_approved=True).aggregate(Avg('rating'))['rating__avg'] or 0
    
    def get_review_count(self, obj):
        return obj.reviews.filter(is_approved=True).count()
    
    def get_is_in_wishlist(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Wishlist.objects.filter(
                customer=request.user, 
                product=obj
            ).exists()
        return False


class CartItemSerializer(serializers.ModelSerializer):
    """Serializer for cart items"""
    product = ProductSerializer(read_only=True)
    variant = ProductVariantSerializer(read_only=True)
    product_id = serializers.IntegerField(write_only=True)
    variant_id = serializers.IntegerField(write_only=True, required=False)
    total_price_toman = serializers.ReadOnlyField()
    total_price_usd = serializers.ReadOnlyField()
    
    class Meta:
        model = CartItem
        fields = [
            'id', 'product', 'variant', 'product_id', 'variant_id',
            'quantity', 'total_price_toman', 'total_price_usd', 'added_at'
        ]


class CartSerializer(serializers.ModelSerializer):
    """Serializer for shopping cart"""
    items = CartItemSerializer(many=True, read_only=True)
    total_items = serializers.ReadOnlyField()
    total_price_toman = serializers.ReadOnlyField()
    total_price_usd = serializers.ReadOnlyField()
    
    class Meta:
        model = Cart
        fields = [
            'id', 'items', 'total_items', 'total_price_toman', 
            'total_price_usd', 'created_at', 'updated_at'
        ]


class WishlistSerializer(serializers.ModelSerializer):
    """Serializer for wishlist items"""
    product = ProductSerializer(read_only=True)
    variant = ProductVariantSerializer(read_only=True)
    
    class Meta:
        model = Wishlist
        fields = ['id', 'product', 'variant', 'added_at']


class AddressSerializer(serializers.ModelSerializer):
    """Serializer for customer addresses"""
    class Meta:
        model = Address
        fields = [
            'id', 'label', 'receiver_name', 'street_address', 'city',
            'province', 'vahed', 'phone', 'country', 'postal_code',
            'created_at', 'updated_at'
        ]


class OrderItemSerializer(serializers.ModelSerializer):
    """Serializer for order items"""
    product = ProductSerializer(read_only=True)
    variant = ProductVariantSerializer(read_only=True)
    item_status = serializers.CharField(read_only=True)
    
    class Meta:
        model = OrderItem
        fields = [
            'id', 'product', 'variant', 'quantity', 'unit_price_toman',
            'unit_price_usd', 'total_price_toman', 'total_price_usd',
            'item_status', 'quantity_returned', 'quantity_rejected',
            'can_return', 'can_reject'
        ]


class OrderSerializer(serializers.ModelSerializer):
    """Serializer for orders"""
    items = OrderItemSerializer(many=True, read_only=True)
    delivery_address = AddressSerializer(read_only=True)
    
    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'status', 'payment_method', 'payment_status',
            'subtotal_toman', 'subtotal_usd', 'shipping_cost_toman', 'shipping_cost_usd',
            'discount_amount_toman', 'discount_amount_usd', 'total_toman', 'total_usd',
            'delivery_address', 'delivery_option', 'delivery_status', 'tracking_number',
            'estimated_delivery', 'delivered_at', 'created_at', 'updated_at', 'paid_at',
            'notes', 'discount_code', 'items', 'return_requested_at', 'return_reason',
            'refund_amount_toman', 'refund_amount_usd'
        ]


class OrderReturnItemSerializer(serializers.ModelSerializer):
    """Serializer for return items"""
    order_item = OrderItemSerializer(read_only=True)
    
    class Meta:
        model = OrderReturnItem
        fields = [
            'id', 'order_item', 'quantity', 'reason', 'refund_amount_toman',
            'refund_amount_usd', 'status'
        ]


class OrderReturnSerializer(serializers.ModelSerializer):
    """Serializer for order returns"""
    return_items = OrderReturnItemSerializer(many=True, read_only=True)
    order = OrderSerializer(read_only=True)
    
    class Meta:
        model = OrderReturn
        fields = [
            'id', 'return_number', 'order', 'return_type', 'status', 'reason',
            'customer_notes', 'admin_notes', 'refund_amount_toman', 'refund_amount_usd',
            'requested_at', 'approved_at', 'rejected_at', 'rejection_reason',
            'received_at', 'refunded_at', 'return_items'
        ]


class ProductReviewSerializer(serializers.ModelSerializer):
    """Serializer for product reviews"""
    customer_name = serializers.CharField(source='customer.get_full_name', read_only=True)
    images = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductReview
        fields = [
            'id', 'customer_name', 'rating', 'title', 'comment',
            'is_verified_purchase', 'is_featured', 'created_at', 'images'
        ]
    
    def get_images(self, obj):
        return [img.image.url for img in obj.images.all()]


class CustomerNotificationSerializer(serializers.ModelSerializer):
    """Serializer for customer notifications"""
    class Meta:
        model = CustomerNotification
        fields = [
            'id', 'notification_type', 'title', 'message', 'is_read',
            'created_at', 'read_at'
        ]


# ========================================
# API VIEWS
# ========================================

class CustomerRegistrationView(APIView):
    """Customer registration endpoint"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = CustomerRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                },
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                }
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CustomerLoginView(APIView):
    """Customer login endpoint"""
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = CustomerLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            
            # Generate JWT tokens
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                },
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                }
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProductListView(generics.ListAPIView):
    """Product listing with search and filters"""
    serializer_class = ProductSerializer
    permission_classes = [AllowAny]
    pagination_class = PageNumberPagination
    
    def get_queryset(self):
        queryset = Product.objects.filter(is_active=True).select_related('category', 'supplier')
        
        # Search by name or description
        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | Q(description__icontains=search)
            )
        
        # Filter by category
        category_id = self.request.query_params.get('category')
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        
        # Filter by price range
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        if min_price:
            queryset = queryset.filter(price_toman__gte=min_price)
        if max_price:
            queryset = queryset.filter(price_toman__lte=max_price)
        
        # Filter by supplier
        supplier_id = self.request.query_params.get('supplier')
        if supplier_id:
            queryset = queryset.filter(supplier_id=supplier_id)
        
        # Sort options
        sort_by = self.request.query_params.get('sort_by', 'created_at')
        sort_order = self.request.query_params.get('sort_order', 'desc')
        
        if sort_order == 'desc':
            sort_by = f'-{sort_by}'
        
        queryset = queryset.order_by(sort_by)
        
        return queryset


class ProductDetailView(generics.RetrieveAPIView):
    """Product detail view"""
    serializer_class = ProductSerializer
    permission_classes = [AllowAny]
    queryset = Product.objects.filter(is_active=True)


class CartView(APIView):
    """Cart management"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Get user's cart"""
        cart, created = Cart.objects.get_or_create(customer=request.user)
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    
    def post(self, request):
        """Add item to cart"""
        cart, created = Cart.objects.get_or_create(customer=request.user)
        
        product_id = request.data.get('product_id')
        variant_id = request.data.get('variant_id')
        quantity = int(request.data.get('quantity', 1))
        
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if variant exists and is available
        variant = None
        if variant_id:
            try:
                variant = ProductVariant.objects.get(
                    id=variant_id, 
                    product=product, 
                    is_active=True
                )
                if variant.stock_quantity < quantity:
                    return Response(
                        {'error': 'Insufficient stock'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
            except ProductVariant.DoesNotExist:
                return Response(
                    {'error': 'Variant not found'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
        
        # Add or update cart item
        cart_item, created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            variant=variant,
            defaults={'quantity': quantity}
        )
        
        if not created:
            cart_item.quantity += quantity
            cart_item.save()
        
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    
    def put(self, request):
        """Update cart item quantity"""
        cart, created = Cart.objects.get_or_create(customer=request.user)
        
        item_id = request.data.get('item_id')
        quantity = int(request.data.get('quantity', 1))
        
        try:
            cart_item = CartItem.objects.get(id=item_id, cart=cart)
            cart_item.quantity = quantity
            cart_item.save()
            
            serializer = CartSerializer(cart)
            return Response(serializer.data)
        except CartItem.DoesNotExist:
            return Response({'error': 'Cart item not found'}, status=status.HTTP_404_NOT_FOUND)
    
    def delete(self, request):
        """Remove item from cart"""
        cart, created = Cart.objects.get_or_create(customer=request.user)
        
        item_id = request.data.get('item_id')
        
        try:
            cart_item = CartItem.objects.get(id=item_id, cart=cart)
            cart_item.delete()
            
            serializer = CartSerializer(cart)
            return Response(serializer.data)
        except CartItem.DoesNotExist:
            return Response({'error': 'Cart item not found'}, status=status.HTTP_404_NOT_FOUND)


class WishlistView(APIView):
    """Wishlist management"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Get user's wishlist"""
        wishlist_items = Wishlist.objects.filter(customer=request.user)
        serializer = WishlistSerializer(wishlist_items, many=True)
        return Response(serializer.data)
    
    def post(self, request):
        """Add item to wishlist"""
        product_id = request.data.get('product_id')
        variant_id = request.data.get('variant_id')
        
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)
        
        variant = None
        if variant_id:
            try:
                variant = ProductVariant.objects.get(
                    id=variant_id, 
                    product=product, 
                    is_active=True
                )
            except ProductVariant.DoesNotExist:
                return Response(
                    {'error': 'Variant not found'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
        
        wishlist_item, created = Wishlist.objects.get_or_create(
            customer=request.user,
            product=product,
            variant=variant
        )
        
        if created:
            serializer = WishlistSerializer(wishlist_item)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        else:
            return Response({'message': 'Item already in wishlist'}, status=status.HTTP_200_OK)
    
    def delete(self, request):
        """Remove item from wishlist"""
        product_id = request.data.get('product_id')
        variant_id = request.data.get('variant_id')
        
        try:
            wishlist_item = Wishlist.objects.get(
                customer=request.user,
                product_id=product_id,
                variant_id=variant_id
            )
            wishlist_item.delete()
            return Response({'message': 'Item removed from wishlist'}, status=status.HTTP_200_OK)
        except Wishlist.DoesNotExist:
            return Response({'error': 'Wishlist item not found'}, status=status.HTTP_404_NOT_FOUND)


class CheckoutView(APIView):
    """Checkout process - Enhanced with address handling"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        """Create order from cart"""
        from decimal import InvalidOperation
        
        try:
            cart, created = Cart.objects.get_or_create(customer=request.user)
            
            if not cart.items.exists():
                return Response({'error': 'Cart is empty'}, status=status.HTTP_400_BAD_REQUEST)
            
            data = request.data
            
            # Handle address - either address_id or full address details
            address = None
            address_id = data.get('address_id')
            
            if address_id:
                # Use existing address
                try:
                    address = Address.objects.get(id=address_id, customer=request.user)
                except Address.DoesNotExist:
                    return Response({'error': 'Address not found'}, status=status.HTTP_404_NOT_FOUND)
            else:
                # Create new address from provided details
                address_data = {
                    'customer': request.user,
                    'receiver_name': data.get('receiver_name', ''),
                    'street_address': data.get('street_address', ''),
                    'city': data.get('city', ''),
                    'province': data.get('province', ''),
                    'vahed': data.get('unit', data.get('vahed', '')),
                    'phone': data.get('phone', ''),
                    'country': data.get('country', 'Iran'),
                    'postal_code': data.get('postal_code', ''),
                    'label': data.get('address_label', 'Home'),
                }
                
                # Validate required fields
                required_fields = ['receiver_name', 'street_address', 'city', 'phone', 'country']
                missing_fields = [field for field in required_fields if not address_data.get(field)]
                
                if missing_fields:
                    return Response({
                        'error': f'Missing required address fields: {", ".join(missing_fields)}'
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                address = Address.objects.create(**address_data)
            
            # Get delivery and payment options
            delivery_option = data.get('delivery_option', 'standard')
            payment_method = data.get('payment_method', 'cod')
            discount_code = data.get('discount_code', '')
            delivery_notes = data.get('delivery_notes', '')
            
            # Calculate totals safely
            try:
                subtotal_toman = cart.get_total_price()
            except (TypeError, ValueError, AttributeError, InvalidOperation) as e:
                print(f"⚠️ Error calculating cart total: {e}")
                subtotal_toman = 0
                for item in cart.items.all():
                    try:
                        subtotal_toman += item.get_total_price()
                    except:
                        continue
            
            # Calculate shipping cost based on delivery option
            shipping_cost_toman = 0
            if delivery_option == 'express':
                shipping_cost_toman = 50000  # Example: 50,000 Toman for express
            elif delivery_option == 'standard':
                shipping_cost_toman = 30000  # Example: 30,000 Toman for standard
            
            # Calculate discount (placeholder - implement your discount logic)
            discount_amount_toman = 0
            if discount_code:
                # TODO: Implement discount code validation
                pass
            
            total_toman = subtotal_toman + shipping_cost_toman - discount_amount_toman
            
            # Create order
            order = Order.objects.create(
                customer=request.user,
                delivery_address=address,
                delivery_option=delivery_option,
                discount_code=discount_code,
                notes=delivery_notes,
                subtotal_toman=subtotal_toman,
                shipping_cost_toman=shipping_cost_toman,
                discount_amount_toman=discount_amount_toman,
                total_toman=total_toman,
                payment_method=payment_method,
                status='pending' if payment_method == 'cod' else 'paid',
                payment_status='pending' if payment_method == 'cod' else 'paid'
            )
            
            # Create order items from cart items
            for cart_item in cart.items.all():
                try:
                    unit_price = cart_item.get_unit_price_toman()
                    total_price = cart_item.get_total_price()
                    
                    OrderItem.objects.create(
                        order=order,
                        product=cart_item.product,
                        variant=cart_item.variant,
                        quantity=cart_item.quantity,
                        unit_price_toman=unit_price,
                        total_price_toman=total_price,
                        item_status='pending'
                    )
                except Exception as e:
                    print(f"⚠️ Error creating order item: {e}")
                    continue
            
            # Clear cart after successful order creation
            cart.items.all().delete()
            
            serializer = OrderSerializer(order)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            import traceback
            print(f"❌ Checkout error: {e}")
            print(f"📋 Traceback: {traceback.format_exc()}")
            return Response({
                'error': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class OrderListView(generics.ListAPIView):
    """User's order history"""
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Order.objects.filter(customer=self.request.user).order_by('-created_at')


class OrderDetailView(generics.RetrieveAPIView):
    """Order detail view"""
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Order.objects.filter(customer=self.request.user)


class OrderReturnRequestView(APIView):
    """Request order return (full or partial)"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, order_id):
        """Create a return request for an order"""
        try:
            order = Order.objects.get(id=order_id, customer=request.user)
            
            # Check if order can be returned
            if order.status not in ['delivered', 'partially_returned']:
                return Response({
                    'error': f'Order with status "{order.status}" cannot be returned. Only delivered orders can be returned.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            data = request.data
            return_type = data.get('return_type', 'full')  # 'full' or 'partial'
            reason = data.get('reason', '')
            customer_notes = data.get('customer_notes', '')
            items_to_return = data.get('items', [])  # List of {order_item_id, quantity, reason}
            
            if not reason:
                return Response({'error': 'Return reason is required'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Create return request
            return_request = OrderReturn.objects.create(
                order=order,
                return_type=return_type,
                reason=reason,
                customer_notes=customer_notes,
                status='requested'
            )
            
            # Calculate refund amount
            total_refund = 0
            
            if return_type == 'full':
                # Return all items
                for order_item in order.items.all():
                    if order_item.can_return:
                        OrderReturnItem.objects.create(
                            return_request=return_request,
                            order_item=order_item,
                            quantity=order_item.quantity - order_item.quantity_returned,
                            reason=reason,
                            refund_amount_toman=order_item.unit_price_toman * (order_item.quantity - order_item.quantity_returned),
                            status='requested'
                        )
                        total_refund += float(order_item.unit_price_toman) * (order_item.quantity - order_item.quantity_returned)
            else:
                # Partial return - specific items
                if not items_to_return:
                    return Response({
                        'error': 'Items list is required for partial return'
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                for item_data in items_to_return:
                    order_item_id = item_data.get('order_item_id')
                    quantity = item_data.get('quantity')
                    item_reason = item_data.get('reason', reason)
                    
                    try:
                        order_item = OrderItem.objects.get(id=order_item_id, order=order)
                        
                        if not order_item.can_return:
                            continue
                        
                        available_quantity = order_item.quantity - order_item.quantity_returned
                        if quantity > available_quantity:
                            quantity = available_quantity
                        
                        if quantity > 0:
                            OrderReturnItem.objects.create(
                                return_request=return_request,
                                order_item=order_item,
                                quantity=quantity,
                                reason=item_reason,
                                refund_amount_toman=order_item.unit_price_toman * quantity,
                                status='requested'
                            )
                            total_refund += float(order_item.unit_price_toman) * quantity
                    except OrderItem.DoesNotExist:
                        continue
            
            # Update return request refund amount
            return_request.refund_amount_toman = total_refund
            return_request.save()
            
            # Update order status
            order.return_requested_at = timezone.now()
            order.return_reason = reason
            if return_type == 'full':
                order.status = 'return_requested'
            else:
                order.status = 'partially_returned'
            order.save()
            
            serializer = OrderReturnSerializer(return_request)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            import traceback
            print(f"❌ Return request error: {e}")
            print(f"📋 Traceback: {traceback.format_exc()}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class OrderItemReturnRequestView(APIView):
    """Request return for a specific order item"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, order_id, item_id):
        """Request return for a specific order item"""
        try:
            order = Order.objects.get(id=order_id, customer=request.user)
            order_item = OrderItem.objects.get(id=item_id, order=order)
            
            if not order_item.can_return:
                return Response({
                    'error': 'This item cannot be returned'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            data = request.data
            quantity = data.get('quantity', order_item.quantity - order_item.quantity_returned)
            reason = data.get('reason', '')
            
            if not reason:
                return Response({'error': 'Return reason is required'}, status=status.HTTP_400_BAD_REQUEST)
            
            available_quantity = order_item.quantity - order_item.quantity_returned
            if quantity > available_quantity:
                quantity = available_quantity
            
            if quantity <= 0:
                return Response({
                    'error': 'No items available to return'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Check if there's an existing return request for this order
            existing_return = OrderReturn.objects.filter(
                order=order,
                status__in=['requested', 'approved', 'in_transit']
            ).first()
            
            if not existing_return:
                # Create new return request
                return_request = OrderReturn.objects.create(
                    order=order,
                    return_type='partial',
                    reason=reason,
                    status='requested'
                )
            else:
                return_request = existing_return
            
            # Create or update return item
            return_item, created = OrderReturnItem.objects.get_or_create(
                return_request=return_request,
                order_item=order_item,
                defaults={
                    'quantity': quantity,
                    'reason': reason,
                    'refund_amount_toman': order_item.unit_price_toman * quantity,
                    'status': 'requested'
                }
            )
            
            if not created:
                # Update existing return item
                return_item.quantity = quantity
                return_item.reason = reason
                return_item.refund_amount_toman = order_item.unit_price_toman * quantity
                return_item.save()
            
            # Update return request total refund
            return_request.refund_amount_toman = sum(
                float(item.refund_amount_toman) for item in return_request.return_items.all()
            )
            return_request.save()
            
            # Update order item status
            order_item.return_requested_at = timezone.now()
            order_item.return_reason = reason
            order_item.item_status = 'return_requested'
            order_item.save()
            
            # Update order status
            if order.status == 'delivered':
                order.status = 'partially_returned'
                order.save()
            
            serializer = OrderReturnItemSerializer(return_item)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
        except OrderItem.DoesNotExist:
            return Response({'error': 'Order item not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            import traceback
            print(f"❌ Item return request error: {e}")
            print(f"📋 Traceback: {traceback.format_exc()}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class OrderRejectView(APIView):
    """Reject an order (customer rejects entire order)"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, order_id):
        """Reject an order"""
        try:
            order = Order.objects.get(id=order_id, customer=request.user)
            
            # Only allow rejection of delivered orders
            if order.status != 'delivered':
                return Response({
                    'error': f'Order with status "{order.status}" cannot be rejected. Only delivered orders can be rejected.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            data = request.data
            reason = data.get('reason', '')
            
            if not reason:
                return Response({'error': 'Rejection reason is required'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Update order status
            order.status = 'cancelled'
            order.return_reason = reason
            order.save()
            
            # Update all order items
            for order_item in order.items.all():
                order_item.item_status = 'rejected'
                order_item.quantity_rejected = order_item.quantity
                order_item.save()
            
            serializer = OrderSerializer(order)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            import traceback
            print(f"❌ Order rejection error: {e}")
            print(f"📋 Traceback: {traceback.format_exc()}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class OrderItemRejectView(APIView):
    """Reject a specific order item"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, order_id, item_id):
        """Reject a specific order item"""
        try:
            order = Order.objects.get(id=order_id, customer=request.user)
            order_item = OrderItem.objects.get(id=item_id, order=order)
            
            if not order_item.can_reject:
                return Response({
                    'error': 'This item cannot be rejected'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            data = request.data
            quantity = data.get('quantity', order_item.quantity - order_item.quantity_rejected)
            reason = data.get('reason', '')
            
            if not reason:
                return Response({'error': 'Rejection reason is required'}, status=status.HTTP_400_BAD_REQUEST)
            
            available_quantity = order_item.quantity - order_item.quantity_rejected
            if quantity > available_quantity:
                quantity = available_quantity
            
            if quantity <= 0:
                return Response({
                    'error': 'No items available to reject'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update order item
            order_item.quantity_rejected += quantity
            if order_item.quantity_rejected >= order_item.quantity:
                order_item.item_status = 'rejected'
            order_item.save()
            
            # Update order status if all items are rejected
            all_rejected = all(
                item.quantity_rejected >= item.quantity 
                for item in order.items.all()
            )
            if all_rejected:
                order.status = 'cancelled'
                order.save()
            elif order.status == 'delivered':
                order.status = 'partially_returned'
                order.save()
            
            serializer = OrderItemSerializer(order_item)
            return Response(serializer.data, status=status.HTTP_200_OK)
            
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
        except OrderItem.DoesNotExist:
            return Response({'error': 'Order item not found'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            import traceback
            print(f"❌ Item rejection error: {e}")
            print(f"📋 Traceback: {traceback.format_exc()}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class OrderReturnListView(generics.ListAPIView):
    """List all return requests for a user"""
    serializer_class = OrderReturnSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return OrderReturn.objects.filter(order__customer=self.request.user).order_by('-requested_at')


class OrderReturnDetailView(generics.RetrieveAPIView):
    """Get details of a specific return request"""
    serializer_class = OrderReturnSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return OrderReturn.objects.filter(order__customer=self.request.user)


class ProductReviewView(APIView):
    """Product review management"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request, product_id):
        """Get product reviews"""
        reviews = ProductReview.objects.filter(
            product_id=product_id, 
            is_approved=True
        ).order_by('-created_at')
        
        serializer = ProductReviewSerializer(reviews, many=True)
        return Response(serializer.data)
    
    def post(self, request, product_id):
        """Create product review"""
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if user has purchased this product
        has_purchased = OrderItem.objects.filter(
            order__customer=request.user,
            order__status__in=['delivered', 'paid'],
            product=product
        ).exists()
        
        if not has_purchased:
            return Response(
                {'error': 'You must purchase this product before reviewing'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user already reviewed this product
        variant_id = request.data.get('variant_id')
        if ProductReview.objects.filter(
            customer=request.user,
            product=product,
            variant_id=variant_id
        ).exists():
            return Response(
                {'error': 'You have already reviewed this product'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = ProductReviewSerializer(data=request.data)
        if serializer.is_valid():
            review = serializer.save(
                customer=request.user,
                product=product,
                is_verified_purchase=True
            )
            return Response(ProductReviewSerializer(review).data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class NotificationListView(generics.ListAPIView):
    """User notifications"""
    serializer_class = CustomerNotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return CustomerNotification.objects.filter(
            customer=self.request.user
        ).order_by('-created_at')


class NotificationMarkReadView(APIView):
    """Mark notification as read"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request, notification_id):
        try:
            notification = CustomerNotification.objects.get(
                id=notification_id,
                customer=request.user
            )
            notification.is_read = True
            notification.read_at = timezone.now()
            notification.save()
            
            return Response({'message': 'Notification marked as read'}, status=status.HTTP_200_OK)
        except CustomerNotification.DoesNotExist:
            return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)


# ========================================
# URL PATTERNS (to be added to urls.py)
# ========================================

"""
Add these URL patterns to your shop/urls.py:

urlpatterns += [
    # Authentication
    path('api/customer/register/', CustomerRegistrationView.as_view(), name='customer_register'),
    path('api/customer/login/', CustomerLoginView.as_view(), name='customer_login'),
    
    # Products
    path('api/customer/products/', ProductListView.as_view(), name='customer_products'),
    path('api/customer/products/<int:pk>/', ProductDetailView.as_view(), name='customer_product_detail'),
    
    # Cart
    path('api/customer/cart/', CartView.as_view(), name='customer_cart'),
    
    # Wishlist
    path('api/customer/wishlist/', WishlistView.as_view(), name='customer_wishlist'),
    
    # Checkout & Orders
    path('api/customer/checkout/', CheckoutView.as_view(), name='customer_checkout'),
    path('api/customer/orders/', OrderListView.as_view(), name='customer_orders'),
    path('api/customer/orders/<int:pk>/', OrderDetailView.as_view(), name='customer_order_detail'),
    
    # Reviews
    path('api/customer/products/<int:product_id>/reviews/', ProductReviewView.as_view(), name='customer_reviews'),
    
    # Notifications
    path('api/customer/notifications/', NotificationListView.as_view(), name='customer_notifications'),
    path('api/customer/notifications/<int:notification_id>/read/', NotificationMarkReadView.as_view(), name='customer_notification_read'),
]
"""
