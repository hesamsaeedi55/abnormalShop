from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import (
    SupplierUser, Supplier, Store, SupplierRole, SupplierInvitation,
    User, SupplierAdmin  # Legacy models
)


@admin.register(SupplierUser)
class SupplierUserAdmin(UserAdmin):
    """Admin interface for SupplierUser"""
    list_display = ['email', 'first_name', 'last_name', 'is_active', 'is_staff', 'created_at']
    list_filter = ['is_active', 'is_staff', 'is_superuser', 'created_at']
    search_fields = ['email', 'first_name', 'last_name']
    ordering = ['-created_at']
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('first_name', 'last_name', 'phone_number')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
        ('Supplier Info', {'fields': ('is_email_verified', 'email_verification_token')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'first_name', 'last_name', 'password1', 'password2'),
        }),
    )


@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    """Admin interface for Supplier"""
    list_display = ['name', 'contact_person', 'email', 'status', 'is_active', 'created_at']
    list_filter = ['status', 'is_active', 'created_at', 'country']
    search_fields = ['name', 'contact_person', 'email', 'phone']
    readonly_fields = ['slug', 'created_at', 'updated_at', 'approved_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'description', 'status', 'is_active')
        }),
        ('Contact Information', {
            'fields': ('contact_person', 'email', 'phone', 'website')
        }),
        ('Address', {
            'fields': ('address_line1', 'address_line2', 'city', 'state', 'country', 'postal_code')
        }),
        ('Business Information', {
            'fields': ('business_license', 'tax_id')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'approved_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).prefetch_related('stores', 'user_roles')


@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    """Admin interface for Store"""
    list_display = ['name', 'supplier', 'store_type', 'status', 'is_active', 'created_at']
    list_filter = ['status', 'is_active', 'store_type', 'currency', 'created_at']
    search_fields = ['name', 'supplier__name', 'contact_email']
    readonly_fields = ['slug', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('supplier', 'name', 'slug', 'description', 'status', 'is_active')
        }),
        ('Store Configuration', {
            'fields': ('store_type', 'currency', 'timezone')
        }),
        ('Contact Information', {
            'fields': ('contact_email', 'contact_phone')
        }),
        ('Address', {
            'fields': ('address_line1', 'address_line2', 'city', 'state', 'country', 'postal_code')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(SupplierRole)
class SupplierRoleAdmin(admin.ModelAdmin):
    """Admin interface for SupplierRole"""
    list_display = ['user', 'supplier', 'role', 'is_active', 'created_at']
    list_filter = ['role', 'is_active', 'created_at']
    search_fields = ['user__email', 'supplier__name']
    filter_horizontal = ['accessible_stores']
    
    fieldsets = (
        ('Role Information', {
            'fields': ('user', 'supplier', 'role', 'is_active')
        }),
        ('Permissions', {
            'fields': ('permissions',)
        }),
        ('Store Access', {
            'fields': ('accessible_stores',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(SupplierInvitation)
class SupplierInvitationAdmin(admin.ModelAdmin):
    """Admin interface for SupplierInvitation"""
    list_display = ['email', 'supplier', 'role', 'status', 'created_at', 'expires_at']
    list_filter = ['status', 'role', 'created_at']
    search_fields = ['email', 'supplier__name', 'invited_by__email']
    readonly_fields = ['token', 'created_at', 'updated_at', 'accepted_at']
    filter_horizontal = ['accessible_stores']
    
    fieldsets = (
        ('Invitation Information', {
            'fields': ('supplier', 'invited_by', 'email', 'role', 'status')
        }),
        ('Permissions', {
            'fields': ('permissions',)
        }),
        ('Store Access', {
            'fields': ('accessible_stores',)
        }),
        ('Invitation Details', {
            'fields': ('token', 'expires_at')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'accepted_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['send_invitation_email', 'mark_as_expired']
    
    def send_invitation_email(self, request, queryset):
        """Send invitation emails for selected invitations"""
        sent_count = 0
        for invitation in queryset.filter(status='pending'):
            try:
                invitation.send_invitation_email()
                sent_count += 1
            except Exception as e:
                self.message_user(request, f"Failed to send email to {invitation.email}: {str(e)}", level='ERROR')
        
        self.message_user(request, f"Successfully sent {sent_count} invitation emails.")
    send_invitation_email.short_description = "Send invitation emails"
    
    def mark_as_expired(self, request, queryset):
        """Mark selected invitations as expired"""
        updated = queryset.filter(status='pending').update(status='expired')
        self.message_user(request, f"Marked {updated} invitations as expired.")
    mark_as_expired.short_description = "Mark as expired"


# Legacy admin registrations for backward compatibility
@admin.register(User)
class UserAdmin(UserAdmin):
    """Legacy User admin - deprecated"""
    pass

@admin.register(SupplierAdmin)
class SupplierAdminAdmin(admin.ModelAdmin):
    """Legacy SupplierAdmin admin - deprecated"""
    list_display = ['user', 'supplier', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['user__username', 'supplier__name']
