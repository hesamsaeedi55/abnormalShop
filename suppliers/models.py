from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from django.utils.text import slugify
from django.core.mail import send_mail
from django.conf import settings
import uuid
import secrets
from django.core.exceptions import ValidationError


class SupplierUserManager(BaseUserManager):
    """Custom manager for SupplierUser"""
    
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError(_('The Email field must be set'))
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        return self.create_user(email, password, **extra_fields)


class SupplierUser(AbstractUser):
    """Custom user model for suppliers"""
    email = models.EmailField(_('email address'), unique=True)
    phone_number = models.CharField(max_length=15, blank=True)
    is_email_verified = models.BooleanField(default=False)
    email_verification_token = models.UUIDField(default=uuid.uuid4, editable=False)
    email_verification_sent_at = models.DateTimeField(null=True, blank=True)
    password_reset_token = models.UUIDField(null=True, blank=True)
    password_reset_sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']
    
    objects = SupplierUserManager()
    
    class Meta:
        verbose_name = _('supplier user')
        verbose_name_plural = _('supplier users')
        
    def __str__(self):
        return self.email
    
    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip()


class Supplier(models.Model):
    """Main supplier entity"""
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('suspended', 'Suspended'),
        ('pending', 'Pending Approval'),
    ]
    
    name = models.CharField(max_length=200, verbose_name='Supplier Name')
    slug = models.SlugField(max_length=200, unique=True, verbose_name='Supplier Slug')
    description = models.TextField(blank=True, verbose_name='Description')
    
    # Contact Information
    contact_person = models.CharField(max_length=100, verbose_name='Contact Person')
    email = models.EmailField(verbose_name='Primary Email')
    phone = models.CharField(max_length=20, verbose_name='Phone Number')
    website = models.URLField(blank=True, verbose_name='Website')
    
    # Address Information
    address_line1 = models.CharField(max_length=255, verbose_name='Address Line 1')
    address_line2 = models.CharField(max_length=255, blank=True, verbose_name='Address Line 2')
    city = models.CharField(max_length=100, verbose_name='City')
    state = models.CharField(max_length=100, verbose_name='State/Province')
    country = models.CharField(max_length=100, verbose_name='Country')
    postal_code = models.CharField(max_length=20, verbose_name='Postal Code')
    
    # Business Information
    business_license = models.CharField(max_length=100, blank=True, verbose_name='Business License')
    tax_id = models.CharField(max_length=100, blank=True, verbose_name='Tax ID')
    
    # Status and Settings
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', verbose_name='Status')
    is_active = models.BooleanField(default=True, verbose_name='Is Active')
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Supplier'
        verbose_name_plural = 'Suppliers'
    
    def __str__(self):
        return self.name
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = self._generate_slug()
        super().save(*args, **kwargs)
    
    def _generate_slug(self):
        """Generate unique slug from supplier name"""
        base_slug = slugify(self.name)
        slug = base_slug
        counter = 1
        while Supplier.objects.filter(slug=slug).exists():
            slug = f"{base_slug}-{counter}"
            counter += 1
        return slug
    
    def get_admins(self):
        """Get all admin users for this supplier"""
        return SupplierUser.objects.filter(supplier_roles__supplier=self, supplier_roles__role='admin')
    
    def get_staff(self):
        """Get all staff users for this supplier"""
        return SupplierUser.objects.filter(supplier_roles__supplier=self, supplier_roles__role='staff')
    
    def get_all_users(self):
        """Get all users associated with this supplier"""
        return SupplierUser.objects.filter(supplier_roles__supplier=self)


class Store(models.Model):
    """Individual stores owned by suppliers"""
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('inactive', 'Inactive'),
        ('maintenance', 'Under Maintenance'),
    ]
    
    supplier = models.ForeignKey(Supplier, on_delete=models.CASCADE, related_name='stores', verbose_name='Supplier')
    name = models.CharField(max_length=200, verbose_name='Store Name')
    slug = models.SlugField(max_length=200, verbose_name='Store Slug')
    description = models.TextField(blank=True, verbose_name='Description')
    
    # Store Information
    store_type = models.CharField(max_length=50, default='online', verbose_name='Store Type')
    currency = models.CharField(max_length=3, default='USD', verbose_name='Currency')
    timezone = models.CharField(max_length=50, default='UTC', verbose_name='Timezone')
    
    # Contact Information
    contact_email = models.EmailField(verbose_name='Store Contact Email')
    contact_phone = models.CharField(max_length=20, blank=True, verbose_name='Store Contact Phone')
    
    # Address Information
    address_line1 = models.CharField(max_length=255, verbose_name='Store Address Line 1')
    address_line2 = models.CharField(max_length=255, blank=True, verbose_name='Store Address Line 2')
    city = models.CharField(max_length=100, verbose_name='Store City')
    state = models.CharField(max_length=100, verbose_name='Store State/Province')
    country = models.CharField(max_length=100, verbose_name='Store Country')
    postal_code = models.CharField(max_length=20, verbose_name='Store Postal Code')
    
    # Status and Settings
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active', verbose_name='Status')
    is_active = models.BooleanField(default=True, verbose_name='Is Active')
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['supplier', 'slug']
        verbose_name = 'Store'
        verbose_name_plural = 'Stores'
    
    def __str__(self):
        return f"{self.supplier.name} - {self.name}"
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = self._generate_slug()
        super().save(*args, **kwargs)
    
    def _generate_slug(self):
        """Generate unique slug for this store within the supplier"""
        base_slug = slugify(self.name)
        slug = base_slug
        counter = 1
        while Store.objects.filter(supplier=self.supplier, slug=slug).exists():
            slug = f"{base_slug}-{counter}"
            counter += 1
        return slug


class SupplierRole(models.Model):
    """Roles and permissions for supplier users"""
    ROLE_CHOICES = [
        ('admin', 'Supplier Admin'),
        ('staff', 'Supplier Staff'),
    ]
    
    PERMISSION_CHOICES = [
        ('manage_stores', 'Manage Stores'),
        ('manage_products', 'Manage Products'),
        ('manage_orders', 'Manage Orders'),
        ('manage_staff', 'Manage Staff'),
        ('view_analytics', 'View Analytics'),
        ('manage_inventory', 'Manage Inventory'),
    ]
    
    user = models.ForeignKey(SupplierUser, on_delete=models.CASCADE, related_name='supplier_roles', verbose_name='User')
    supplier = models.ForeignKey(Supplier, on_delete=models.CASCADE, related_name='user_roles', verbose_name='Supplier')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, verbose_name='Role')
    permissions = models.JSONField(default=list, verbose_name='Permissions')
    is_active = models.BooleanField(default=True, verbose_name='Is Active')
    
    # Store-specific permissions (if user has access to specific stores only)
    accessible_stores = models.ManyToManyField(Store, blank=True, related_name='authorized_users', verbose_name='Accessible Stores')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'supplier']
        verbose_name = 'Supplier Role'
        verbose_name_plural = 'Supplier Roles'
    
    def __str__(self):
        return f"{self.user.email} - {self.supplier.name} ({self.role})"
    
    def has_permission(self, permission):
        """Check if user has specific permission"""
        return permission in self.permissions
    
    def can_access_store(self, store):
        """Check if user can access specific store"""
        if not self.accessible_stores.exists():
            return True  # Access to all stores
        return store in self.accessible_stores.all()


class SupplierInvitation(models.Model):
    """Invitation system for supplier users"""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
    ]
    
    supplier = models.ForeignKey(Supplier, on_delete=models.CASCADE, related_name='invitations', verbose_name='Supplier')
    invited_by = models.ForeignKey(SupplierUser, on_delete=models.CASCADE, related_name='sent_invitations', verbose_name='Invited By')
    email = models.EmailField(verbose_name='Invited Email')
    role = models.CharField(max_length=20, choices=SupplierRole.ROLE_CHOICES, verbose_name='Role')
    permissions = models.JSONField(default=list, verbose_name='Permissions')
    accessible_stores = models.ManyToManyField(Store, blank=True, related_name='invitations', verbose_name='Accessible Stores')
    
    # Invitation details
    token = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', verbose_name='Status')
    expires_at = models.DateTimeField(verbose_name='Expires At')
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Supplier Invitation'
        verbose_name_plural = 'Supplier Invitations'
    
    def __str__(self):
        return f"Invitation for {self.email} to {self.supplier.name}"
    
    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(days=7)
        super().save(*args, **kwargs)
    
    def is_expired(self):
        """Check if invitation has expired"""
        return timezone.now() > self.expires_at
    
    def send_invitation_email(self):
        """Send invitation email"""
        subject = f"Invitation to join {self.supplier.name}"
        message = f"""
        You have been invited to join {self.supplier.name} as a {self.get_role_display()}.
        
        Click the link below to accept the invitation:
        {settings.FRONTEND_URL}/suppliers/accept-invitation/{self.token}/
        
        This invitation expires on {self.expires_at.strftime('%Y-%m-%d %H:%M')}.
        """
        
        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [self.email],
            fail_silently=False,
        )
    
    def accept_invitation(self, user):
        """Accept invitation and create user role"""
        if self.status != 'pending' or self.is_expired():
            raise ValidationError("Invitation is not valid")
        
        # Create supplier role
        role = SupplierRole.objects.create(
            user=user,
            supplier=self.supplier,
            role=self.role,
            permissions=self.permissions,
        )
        
        # Add accessible stores
        role.accessible_stores.set(self.accessible_stores.all())
        
        # Update invitation status
        self.status = 'accepted'
        self.accepted_at = timezone.now()
        self.save()
        
        return role


# Legacy models for backward compatibility
class User(AbstractUser):
    """Legacy user model - deprecated"""
    pass

class SupplierAdmin(models.Model):
    """Legacy supplier admin model - deprecated"""
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    supplier = models.ForeignKey(Supplier, on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.supplier.name}"
