from rest_framework import permissions
from django.core.exceptions import ObjectDoesNotExist


class IsSupplierUser(permissions.BasePermission):
    """
    Custom permission to only allow supplier users to access the view.
    """
    
    def has_permission(self, request, view):
        # Check if user is authenticated
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Check if user is a SupplierUser
        from .models import SupplierUser
        if not isinstance(request.user, SupplierUser):
            return False
        
        # Check if user has any active supplier roles
        return request.user.supplier_roles.filter(is_active=True).exists()


class IsSupplierAdmin(permissions.BasePermission):
    """
    Custom permission to only allow supplier admins to access the view.
    """
    
    def has_permission(self, request, view):
        # Check if user is authenticated
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Check if user is a SupplierUser
        from .models import SupplierUser
        if not isinstance(request.user, SupplierUser):
            return False
        
        # Check if user has any active admin roles
        return request.user.supplier_roles.filter(
            is_active=True, 
            role='admin'
        ).exists()


class IsSupplierStaff(permissions.BasePermission):
    """
    Custom permission to only allow supplier staff to access the view.
    """
    
    def has_permission(self, request, view):
        # Check if user is authenticated
        if not request.user or not request.user.is_authenticated:
            return False
        
        # Check if user is a SupplierUser
        from .models import SupplierUser
        if not isinstance(request.user, SupplierUser):
            return False
        
        # Check if user has any active roles (admin or staff)
        return request.user.supplier_roles.filter(is_active=True).exists()


class CanManageStore(permissions.BasePermission):
    """
    Custom permission to check if user can manage a specific store.
    """
    
    def has_permission(self, request, view):
        # First check if user is a supplier user
        if not IsSupplierUser().has_permission(request, view):
            return False
        
        # For GET requests, allow if user has any access to stores
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # For other methods, check specific permissions
        return self._has_store_permission(request, view)
    
    def has_object_permission(self, request, view, obj):
        # Check if user can access this specific store
        user = request.user
        for role in user.supplier_roles.filter(is_active=True):
            if role.can_access_store(obj):
                # For write operations, check if user has manage_stores permission
                if request.method in permissions.SAFE_METHODS:
                    return True
                return role.has_permission('manage_stores')
        return False
    
    def _has_store_permission(self, request, view):
        """Check if user has permission to manage stores"""
        user = request.user
        for role in user.supplier_roles.filter(is_active=True):
            if role.has_permission('manage_stores'):
                return True
        return False


class CanManageProducts(permissions.BasePermission):
    """
    Custom permission to check if user can manage products.
    """
    
    def has_permission(self, request, view):
        # First check if user is a supplier user
        if not IsSupplierUser().has_permission(request, view):
            return False
        
        # Check if user has manage_products permission
        user = request.user
        for role in user.supplier_roles.filter(is_active=True):
            if role.has_permission('manage_products'):
                return True
        return False


class CanManageOrders(permissions.BasePermission):
    """
    Custom permission to check if user can manage orders.
    """
    
    def has_permission(self, request, view):
        # First check if user is a supplier user
        if not IsSupplierUser().has_permission(request, view):
            return False
        
        # Check if user has manage_orders permission
        user = request.user
        for role in user.supplier_roles.filter(is_active=True):
            if role.has_permission('manage_orders'):
                return True
        return False


class CanManageStaff(permissions.BasePermission):
    """
    Custom permission to check if user can manage staff.
    """
    
    def has_permission(self, request, view):
        # First check if user is a supplier user
        if not IsSupplierUser().has_permission(request, view):
            return False
        
        # Check if user has manage_staff permission
        user = request.user
        for role in user.supplier_roles.filter(is_active=True):
            if role.has_permission('manage_staff'):
                return True
        return False


class CanViewAnalytics(permissions.BasePermission):
    """
    Custom permission to check if user can view analytics.
    """
    
    def has_permission(self, request, view):
        # First check if user is a supplier user
        if not IsSupplierUser().has_permission(request, view):
            return False
        
        # Check if user has view_analytics permission
        user = request.user
        for role in user.supplier_roles.filter(is_active=True):
            if role.has_permission('view_analytics'):
                return True
        return False


class CanManageInventory(permissions.BasePermission):
    """
    Custom permission to check if user can manage inventory.
    """
    
    def has_permission(self, request, view):
        # First check if user is a supplier user
        if not IsSupplierUser().has_permission(request, view):
            return False
        
        # Check if user has manage_inventory permission
        user = request.user
        for role in user.supplier_roles.filter(is_active=True):
            if role.has_permission('manage_inventory'):
                return True
        return False


class SupplierScopedPermission(permissions.BasePermission):
    """
    Base permission class for supplier-scoped operations.
    Ensures users can only access data from their own suppliers.
    """
    
    def has_permission(self, request, view):
        # First check if user is a supplier user
        if not IsSupplierUser().has_permission(request, view):
            return False
        
        # For write operations, check specific permissions
        if request.method not in permissions.SAFE_METHODS:
            return self._check_write_permission(request, view)
        
        return True
    
    def _check_write_permission(self, request, view):
        """Override in subclasses to check specific write permissions"""
        return True
    
    def get_user_suppliers(self, user):
        """Get all suppliers the user has access to"""
        return user.supplier_roles.filter(is_active=True).values_list('supplier', flat=True)
    
    def get_user_stores(self, user):
        """Get all stores the user has access to"""
        stores = []
        for role in user.supplier_roles.filter(is_active=True):
            if role.accessible_stores.exists():
                stores.extend(role.accessible_stores.values_list('id', flat=True))
            else:
                # User has access to all stores of this supplier
                stores.extend(role.supplier.stores.values_list('id', flat=True))
        return stores
