"""
Customer Platform Models for iOS E-commerce App
===============================================

This file contains all the models needed for the customer-facing platform.
Add these models to your existing shop/models.py or create a new customer app.

Models included:
- Cart & CartItem (with variant support)
- Wishlist
- Order & OrderItem
- ProductReview & ReviewImage
- CustomerNotification
- PaymentMethod
- DeliveryOption
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
import uuid

User = get_user_model()

class Cart(models.Model):
    """
    Shopping cart for customers
    Supports persistent carts across sessions
    """
    customer = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='carts',
        null=True, blank=True,
        help_text='Customer if logged in, null for anonymous'
    )
    session_key = models.CharField(
        max_length=40, 
        blank=True,
        help_text='Session key for anonymous users'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = [['customer', 'session_key']]
        verbose_name = 'Shopping Cart'
        verbose_name_plural = 'Shopping Carts'
    
    def __str__(self):
        if self.customer:
            return f"Cart for {self.customer.email}"
        return f"Anonymous cart {self.session_key[:8]}..."
    
    @property
    def total_items(self):
        return sum(item.quantity for item in self.items.all())
    
    @property
    def total_price_toman(self):
        return sum(item.total_price_toman for item in self.items.all())
    
    @property
    def total_price_usd(self):
        return sum(item.total_price_usd for item in self.items.all())


class CartItem(models.Model):
    """
    Individual items in shopping cart
    Supports product variants (color, size, etc.)
    """
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey('Product', on_delete=models.CASCADE)
    variant = models.ForeignKey(
        'ProductVariant', 
        on_delete=models.CASCADE,
        null=True, blank=True,
        help_text='Specific product variant (color, size, etc.)'
    )
    quantity = models.PositiveIntegerField(
        default=1,
        validators=[MinValueValidator(1)]
    )
    added_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = [['cart', 'product', 'variant']]
        verbose_name = 'Cart Item'
        verbose_name_plural = 'Cart Items'
    
    def __str__(self):
        variant_str = f" ({self.variant.variant_name})" if self.variant else ""
        return f"{self.product.name}{variant_str} x{self.quantity}"
    
    @property
    def unit_price_toman(self):
        """Get unit price in Toman"""
        if self.variant:
            return self.variant.price_toman
        return self.product.price_toman
    
    @property
    def unit_price_usd(self):
        """Get unit price in USD"""
        if self.variant:
            return self.variant.price_usd
        return self.product.price_usd
    
    @property
    def total_price_toman(self):
        """Calculate total price in Toman"""
        return self.unit_price_toman * self.quantity
    
    @property
    def total_price_usd(self):
        """Calculate total price in USD"""
        if self.unit_price_usd:
            return self.unit_price_usd * self.quantity
        return None


class Wishlist(models.Model):
    """
    Customer wishlist for saving products for later
    """
    customer = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='wishlist_items'
    )
    product = models.ForeignKey('Product', on_delete=models.CASCADE)
    variant = models.ForeignKey(
        'ProductVariant',
        on_delete=models.CASCADE,
        null=True, blank=True,
        help_text='Specific variant if added to wishlist'
    )
    added_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = [['customer', 'product', 'variant']]
        verbose_name = 'Wishlist Item'
        verbose_name_plural = 'Wishlist Items'
    
    def __str__(self):
        variant_str = f" ({self.variant.variant_name})" if self.variant else ""
        return f"{self.customer.email} - {self.product.name}{variant_str}"


class Order(models.Model):
    """
    Customer orders with full order management
    """
    ORDER_STATUS_CHOICES = [
        ('pending', 'Pending Payment'),
        ('paid', 'Paid'),
        ('processing', 'Processing'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded'),
        ('return_requested', 'Return Requested'),
        ('return_approved', 'Return Approved'),
        ('return_rejected', 'Return Rejected'),
        ('returned', 'Returned'),
        ('partially_returned', 'Partially Returned'),
    ]
    
    PAYMENT_METHOD_CHOICES = [
        ('cod', 'Cash on Delivery'),
        ('online', 'Online Payment'),
        ('bank_transfer', 'Bank Transfer'),
    ]
    
    DELIVERY_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('preparing', 'Preparing'),
        ('shipped', 'Shipped'),
        ('out_for_delivery', 'Out for Delivery'),
        ('delivered', 'Delivered'),
        ('failed', 'Delivery Failed'),
    ]
    
    # Order identification
    order_number = models.CharField(
        max_length=20, 
        unique=True,
        help_text='Unique order number (e.g., ORD-2024-001)'
    )
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    
    # Order status
    status = models.CharField(
        max_length=20, 
        choices=ORDER_STATUS_CHOICES, 
        default='pending'
    )
    payment_method = models.CharField(
        max_length=20, 
        choices=PAYMENT_METHOD_CHOICES, 
        default='cod'
    )
    payment_status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('paid', 'Paid'),
            ('failed', 'Failed'),
            ('refunded', 'Refunded'),
        ],
        default='pending'
    )
    
    # Pricing
    subtotal_toman = models.DecimalField(max_digits=12, decimal_places=0)
    subtotal_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    shipping_cost_toman = models.DecimalField(max_digits=12, decimal_places=0, default=0)
    shipping_cost_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    discount_amount_toman = models.DecimalField(max_digits=12, decimal_places=0, default=0)
    discount_amount_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    total_toman = models.DecimalField(max_digits=12, decimal_places=0)
    total_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    
    # Delivery information
    delivery_address = models.ForeignKey(
        'Address', 
        on_delete=models.SET_NULL, 
        null=True,
        related_name='orders'
    )
    delivery_option = models.CharField(
        max_length=50,
        choices=[
            ('standard', 'Standard Delivery'),
            ('express', 'Express Delivery'),
            ('pickup', 'Store Pickup'),
        ],
        default='standard'
    )
    delivery_status = models.CharField(
        max_length=20,
        choices=DELIVERY_STATUS_CHOICES,
        default='pending'
    )
    tracking_number = models.CharField(max_length=100, blank=True)
    estimated_delivery = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    
    # Additional information
    notes = models.TextField(blank=True, help_text='Customer notes or special instructions')
    discount_code = models.CharField(max_length=50, blank=True)
    
    # Return/Rejection tracking
    return_requested_at = models.DateTimeField(null=True, blank=True, help_text='When customer requested return')
    return_reason = models.TextField(blank=True, help_text='Reason for return/rejection')
    return_approved_at = models.DateTimeField(null=True, blank=True)
    return_rejected_at = models.DateTimeField(null=True, blank=True)
    return_rejection_reason = models.TextField(blank=True, help_text='Reason for rejecting return request')
    returned_at = models.DateTimeField(null=True, blank=True)
    refund_amount_toman = models.DecimalField(max_digits=12, decimal_places=0, default=0, help_text='Total refunded amount')
    refund_amount_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    refunded_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Order'
        verbose_name_plural = 'Orders'
    
    def __str__(self):
        return f"Order {self.order_number} - {self.customer.email}"
    
    def save(self, *args, **kwargs):
        if not self.order_number:
            # Generate unique order number
            today = timezone.now().date()
            year = today.year
            month = today.month
            day = today.day
            
            # Get the last order number for today
            last_order = Order.objects.filter(
                order_number__startswith=f"ORD-{year}-{month:02d}-{day:02d}"
            ).order_by('-order_number').first()
            
            if last_order:
                # Extract the sequence number and increment
                try:
                    sequence = int(last_order.order_number.split('-')[-1]) + 1
                except (ValueError, IndexError):
                    sequence = 1
            else:
                sequence = 1
            
            self.order_number = f"ORD-{year}-{month:02d}-{day:02d}-{sequence:03d}"
        
        super().save(*args, **kwargs)


class OrderItem(models.Model):
    """
    Individual items within an order with item-level status tracking
    """
    ITEM_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('return_requested', 'Return Requested'),
        ('return_approved', 'Return Approved'),
        ('return_rejected', 'Return Rejected'),
        ('returned', 'Returned'),
        ('rejected', 'Rejected by Customer'),
        ('cancelled', 'Cancelled'),
    ]
    
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey('Product', on_delete=models.CASCADE)
    variant = models.ForeignKey(
        'ProductVariant',
        on_delete=models.SET_NULL,
        null=True, blank=True
    )
    quantity = models.PositiveIntegerField()
    unit_price_toman = models.DecimalField(max_digits=12, decimal_places=0)
    unit_price_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    total_price_toman = models.DecimalField(max_digits=12, decimal_places=0)
    total_price_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    
    # Item-level status tracking
    item_status = models.CharField(
        max_length=20,
        choices=ITEM_STATUS_CHOICES,
        default='pending',
        help_text='Status of this specific item'
    )
    quantity_returned = models.PositiveIntegerField(default=0, help_text='Number of items returned')
    quantity_rejected = models.PositiveIntegerField(default=0, help_text='Number of items rejected')
    return_requested_at = models.DateTimeField(null=True, blank=True)
    return_reason = models.TextField(blank=True, help_text='Reason for returning this item')
    return_approved_at = models.DateTimeField(null=True, blank=True)
    return_rejected_at = models.DateTimeField(null=True, blank=True)
    return_rejection_reason = models.TextField(blank=True)
    returned_at = models.DateTimeField(null=True, blank=True)
    refund_amount_toman = models.DecimalField(max_digits=12, decimal_places=0, default=0, help_text='Refund amount for this item')
    refund_amount_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    
    class Meta:
        verbose_name = 'Order Item'
        verbose_name_plural = 'Order Items'
    
    def __str__(self):
        variant_str = f" ({self.variant.variant_name})" if self.variant else ""
        return f"{self.product.name}{variant_str} x{self.quantity}"
    
    @property
    def can_return(self):
        """Check if this item can be returned"""
        return self.item_status in ['delivered'] and self.quantity_returned < self.quantity
    
    @property
    def can_reject(self):
        """Check if this item can be rejected"""
        return self.item_status in ['delivered'] and self.quantity_rejected < self.quantity


class OrderReturn(models.Model):
    """
    Tracks order returns (full order or partial)
    """
    RETURN_STATUS_CHOICES = [
        ('requested', 'Return Requested'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('in_transit', 'Return in Transit'),
        ('received', 'Return Received'),
        ('refunded', 'Refunded'),
        ('cancelled', 'Cancelled'),
    ]
    
    RETURN_TYPE_CHOICES = [
        ('full', 'Full Order Return'),
        ('partial', 'Partial Order Return'),
    ]
    
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='returns')
    return_number = models.CharField(max_length=50, unique=True, help_text='Unique return number')
    return_type = models.CharField(max_length=20, choices=RETURN_TYPE_CHOICES, default='full')
    status = models.CharField(max_length=20, choices=RETURN_STATUS_CHOICES, default='requested')
    
    # Return details
    reason = models.TextField(help_text='Reason for return')
    customer_notes = models.TextField(blank=True, help_text='Additional notes from customer')
    admin_notes = models.TextField(blank=True, help_text='Admin notes')
    
    # Financial tracking
    refund_amount_toman = models.DecimalField(max_digits=12, decimal_places=0, default=0)
    refund_amount_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    
    # Timestamps
    requested_at = models.DateTimeField(auto_now_add=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    rejected_at = models.DateTimeField(null=True, blank=True)
    rejection_reason = models.TextField(blank=True)
    received_at = models.DateTimeField(null=True, blank=True)
    refunded_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-requested_at']
        verbose_name = 'Order Return'
        verbose_name_plural = 'Order Returns'
    
    def __str__(self):
        return f"Return {self.return_number} for Order {self.order.order_number}"
    
    def save(self, *args, **kwargs):
        if not self.return_number:
            today = timezone.now().date()
            year = today.year
            month = today.month
            day = today.day
            
            last_return = OrderReturn.objects.filter(
                return_number__startswith=f"RET-{year}-{month:02d}-{day:02d}"
            ).order_by('-return_number').first()
            
            if last_return:
                try:
                    sequence = int(last_return.return_number.split('-')[-1]) + 1
                except (ValueError, IndexError):
                    sequence = 1
            else:
                sequence = 1
            
            self.return_number = f"RET-{year}-{month:02d}-{day:02d}-{sequence:03d}"
        
        super().save(*args, **kwargs)


class OrderReturnItem(models.Model):
    """
    Individual items in a return request
    """
    return_request = models.ForeignKey(OrderReturn, on_delete=models.CASCADE, related_name='return_items')
    order_item = models.ForeignKey(OrderItem, on_delete=models.CASCADE, related_name='returns')
    quantity = models.PositiveIntegerField(help_text='Quantity to return')
    reason = models.TextField(blank=True, help_text='Reason for returning this specific item')
    refund_amount_toman = models.DecimalField(max_digits=12, decimal_places=0, default=0)
    refund_amount_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    
    # Status tracking
    status = models.CharField(
        max_length=20,
        choices=[
            ('requested', 'Requested'),
            ('approved', 'Approved'),
            ('rejected', 'Rejected'),
            ('received', 'Received'),
            ('refunded', 'Refunded'),
        ],
        default='requested'
    )
    
    class Meta:
        verbose_name = 'Return Item'
        verbose_name_plural = 'Return Items'
        unique_together = ('return_request', 'order_item')
    
    def __str__(self):
        return f"{self.quantity}x {self.order_item.product.name} - Return {self.return_request.return_number}"


class ProductReview(models.Model):
    """
    Customer reviews for products
    Only customers who purchased the product can review
    """
    RATING_CHOICES = [
        (1, '1 Star'),
        (2, '2 Stars'),
        (3, '3 Stars'),
        (4, '4 Stars'),
        (5, '5 Stars'),
    ]
    
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews')
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='reviews')
    variant = models.ForeignKey(
        'ProductVariant',
        on_delete=models.SET_NULL,
        null=True, blank=True,
        help_text='Specific variant reviewed'
    )
    order_item = models.ForeignKey(
        OrderItem,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        help_text='Order item that qualifies this review'
    )
    
    rating = models.PositiveIntegerField(
        choices=RATING_CHOICES,
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    title = models.CharField(max_length=200, blank=True)
    comment = models.TextField(blank=True)
    
    # Review status
    is_verified_purchase = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = [['customer', 'product', 'variant']]
        ordering = ['-created_at']
        verbose_name = 'Product Review'
        verbose_name_plural = 'Product Reviews'
    
    def __str__(self):
        return f"{self.customer.email} - {self.product.name} ({self.rating} stars)"
    
    def save(self, *args, **kwargs):
        # Auto-verify if there's a matching order item
        if self.order_item and not self.is_verified_purchase:
            self.is_verified_purchase = True
        super().save(*args, **kwargs)


class ReviewImage(models.Model):
    """
    Images attached to product reviews
    """
    review = models.ForeignKey(ProductReview, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(
        upload_to='reviews/%Y/%m/%d/',
        validators=[FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'webp'])]
    )
    caption = models.CharField(max_length=200, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Review Image'
        verbose_name_plural = 'Review Images'
    
    def __str__(self):
        return f"Image for {self.review}"


class CustomerNotification(models.Model):
    """
    In-app notifications for customers
    """
    NOTIFICATION_TYPES = [
        ('order_update', 'Order Update'),
        ('payment_confirmed', 'Payment Confirmed'),
        ('shipping_update', 'Shipping Update'),
        ('delivery_confirmed', 'Delivery Confirmed'),
        ('promotion', 'Promotion'),
        ('product_restock', 'Product Restock'),
        ('review_request', 'Review Request'),
    ]
    
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=200)
    message = models.TextField()
    
    # Related objects (optional)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, null=True, blank=True)
    product = models.ForeignKey('Product', on_delete=models.CASCADE, null=True, blank=True)
    
    # Status
    is_read = models.BooleanField(default=False)
    is_sent_push = models.BooleanField(default=False)
    is_sent_email = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Customer Notification'
        verbose_name_plural = 'Customer Notifications'
    
    def __str__(self):
        return f"{self.customer.email} - {self.title}"


class PaymentMethod(models.Model):
    """
    Customer saved payment methods
    """
    PAYMENT_TYPES = [
        ('card', 'Credit/Debit Card'),
        ('bank_account', 'Bank Account'),
        ('wallet', 'Digital Wallet'),
    ]
    
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payment_methods')
    payment_type = models.CharField(max_length=20, choices=PAYMENT_TYPES)
    name = models.CharField(max_length=100, help_text='Card name or account name')
    
    # Encrypted payment details (implement proper encryption in production)
    encrypted_details = models.TextField(help_text='Encrypted payment details')
    last_four_digits = models.CharField(max_length=4, blank=True)
    expiry_month = models.PositiveIntegerField(null=True, blank=True)
    expiry_year = models.PositiveIntegerField(null=True, blank=True)
    
    is_default = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Payment Method'
        verbose_name_plural = 'Payment Methods'
    
    def __str__(self):
        return f"{self.customer.email} - {self.name}"


class DeliveryOption(models.Model):
    """
    Available delivery options with pricing
    """
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    cost_toman = models.DecimalField(max_digits=12, decimal_places=0)
    cost_usd = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    estimated_days_min = models.PositiveIntegerField()
    estimated_days_max = models.PositiveIntegerField()
    is_active = models.BooleanField(default=True)
    is_express = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = 'Delivery Option'
        verbose_name_plural = 'Delivery Options'
    
    def __str__(self):
        return f"{self.name} - {self.cost_toman} Toman"


# Signals for automatic operations
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

@receiver(pre_save, sender=OrderItem)
def calculate_order_item_totals(sender, instance, **kwargs):
    """Calculate total prices for order items"""
    instance.total_price_toman = instance.unit_price_toman * instance.quantity
    if instance.unit_price_usd:
        instance.total_price_usd = instance.unit_price_usd * instance.quantity

@receiver(post_save, sender=Order)
def create_order_notification(sender, instance, created, **kwargs):
    """Create notification when order status changes"""
    if created:
        CustomerNotification.objects.create(
            customer=instance.customer,
            notification_type='order_update',
            title='Order Placed',
            message=f'Your order {instance.order_number} has been placed successfully.',
            order=instance
        )
    elif instance.status == 'shipped':
        CustomerNotification.objects.create(
            customer=instance.customer,
            notification_type='shipping_update',
            title='Order Shipped',
            message=f'Your order {instance.order_number} has been shipped.',
            order=instance
        )
    elif instance.status == 'delivered':
        CustomerNotification.objects.create(
            customer=instance.customer,
            notification_type='delivery_confirmed',
            title='Order Delivered',
            message=f'Your order {instance.order_number} has been delivered.',
            order=instance
        )
