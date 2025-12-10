from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.utils.decorators import method_decorator
from django.views import View
import json

from .models import SupplierUser, Supplier, Store, SupplierRole
from .serializers import SupplierSerializer, StoreSerializer, SupplierRoleSerializer
from .permissions import IsSupplierUser


def supplier_landing(request):
    """Supplier landing page"""
    return render(request, 'suppliers/landing.html')


def supplier_login(request):
    """Supplier login view"""
    if request.method == 'POST':
        email = request.POST.get('email')
        password = request.POST.get('password')
        
        user = authenticate(request, username=email, password=password)
        
        if user is not None and isinstance(user, SupplierUser):
            if user.is_active:
                login(request, user)
                return redirect('supplier-dashboard')
            else:
                messages.error(request, 'Your account is disabled.')
        else:
            messages.error(request, 'Invalid email or password.')
    
    return render(request, 'suppliers/login.html')


def supplier_logout(request):
    """Supplier logout view"""
    logout(request)
    messages.success(request, 'You have been logged out successfully.')
    return redirect('supplier-login')


@login_required
def supplier_dashboard(request):
    """Supplier dashboard view"""
    if not isinstance(request.user, SupplierUser):
        messages.error(request, 'Access denied. This is a supplier-only area.')
        return redirect('admin:index')
    
    # Get user's suppliers
    suppliers = Supplier.objects.filter(user_roles__user=request.user, user_roles__is_active=True)
    
    # Calculate stats
    stats = {
        'total_products': 0,
        'total_stores': 0,
        'total_orders': 0,
        'pending_orders': 0,
        'low_stock_alerts': 0,
        'suppliers': []
    }
    
    for supplier in suppliers:
        stores = supplier.stores.filter(is_active=True)
        supplier_data = {
            'id': supplier.id,
            'name': supplier.name,
            'stores_count': stores.count(),
            'products_count': 0,  # TODO: Implement product counting
            'orders_count': 0,    # TODO: Implement order counting
            'pending_orders_count': 0,  # TODO: Implement pending orders counting
            'low_stock_count': 0  # TODO: Implement low stock counting
        }
        
        stats['suppliers'].append(supplier_data)
        stats['total_stores'] += supplier_data['stores_count']
        stats['total_products'] += supplier_data['products_count']
        stats['total_orders'] += supplier_data['orders_count']
        stats['pending_orders'] += supplier_data['pending_orders_count']
        stats['low_stock_alerts'] += supplier_data['low_stock_count']
    
    return render(request, 'suppliers/dashboard.html', {'stats': stats})


@login_required
def supplier_profile(request):
    """Supplier profile view"""
    if not isinstance(request.user, SupplierUser):
        messages.error(request, 'Access denied. This is a supplier-only area.')
        return redirect('admin:index')
    
    if request.method == 'POST':
        # Update profile
        user = request.user
        user.first_name = request.POST.get('first_name', user.first_name)
        user.last_name = request.POST.get('last_name', user.last_name)
        user.phone_number = request.POST.get('phone_number', user.phone_number)
        user.save()
        messages.success(request, 'Profile updated successfully.')
        return redirect('supplier-profile')
    
    # Get user's supplier roles
    roles = request.user.supplier_roles.filter(is_active=True)
    
    return render(request, 'suppliers/profile.html', {'roles': roles})


@login_required
def store_list(request):
    """Store list view"""
    if not isinstance(request.user, SupplierUser):
        messages.error(request, 'Access denied. This is a supplier-only area.')
        return redirect('admin:index')
    
    # Get stores from all suppliers the user has access to
    suppliers = Supplier.objects.filter(user_roles__user=request.user, user_roles__is_active=True)
    stores = Store.objects.filter(supplier__in=suppliers)
    
    return render(request, 'suppliers/store_list.html', {'stores': stores})


@login_required
def store_detail(request, store_id):
    """Store detail view"""
    if not isinstance(request.user, SupplierUser):
        messages.error(request, 'Access denied. This is a supplier-only area.')
        return redirect('admin:index')
    
    # Get store and check access
    suppliers = Supplier.objects.filter(user_roles__user=request.user, user_roles__is_active=True)
    try:
        store = Store.objects.get(id=store_id, supplier__in=suppliers)
    except Store.DoesNotExist:
        messages.error(request, 'Store not found or access denied.')
        return redirect('store-list')
    
    # Check if user has access to this store
    has_access = False
    for role in request.user.supplier_roles.filter(is_active=True):
        if role.can_access_store(store):
            has_access = True
            break
    
    if not has_access:
        messages.error(request, 'Access denied to this store.')
        return redirect('store-list')
    
    if request.method == 'POST':
        # Update store
        store.name = request.POST.get('name', store.name)
        store.description = request.POST.get('description', store.description)
        store.contact_email = request.POST.get('contact_email', store.contact_email)
        store.contact_phone = request.POST.get('contact_phone', store.contact_phone)
        store.address_line1 = request.POST.get('address_line1', store.address_line1)
        store.city = request.POST.get('city', store.city)
        store.country = request.POST.get('country', store.country)
        store.status = request.POST.get('status', store.status)
        store.is_active = request.POST.get('is_active') == 'on'
        store.save()
        messages.success(request, 'Store updated successfully.')
        return redirect('store-detail', store_id=store.id)
    
    return render(request, 'suppliers/store_detail.html', {'store': store})


@login_required
def role_list(request):
    """Role list view"""
    if not isinstance(request.user, SupplierUser):
        messages.error(request, 'Access denied. This is a supplier-only area.')
        return redirect('admin:index')
    
    # Check if user is admin
    is_admin = request.user.supplier_roles.filter(is_active=True, role='admin').exists()
    if not is_admin:
        messages.error(request, 'Access denied. Admin privileges required.')
        return redirect('supplier-dashboard')
    
    # Get roles for user's suppliers
    suppliers = Supplier.objects.filter(user_roles__user=request.user, user_roles__is_active=True)
    roles = SupplierRole.objects.filter(supplier__in=suppliers)
    
    return render(request, 'suppliers/role_list.html', {'roles': roles})


@login_required
def invitation_list(request):
    """Invitation list view"""
    if not isinstance(request.user, SupplierUser):
        messages.error(request, 'Access denied. This is a supplier-only area.')
        return redirect('admin:index')
    
    # Check if user is admin
    is_admin = request.user.supplier_roles.filter(is_active=True, role='admin').exists()
    if not is_admin:
        messages.error(request, 'Access denied. Admin privileges required.')
        return redirect('supplier-dashboard')
    
    # Get invitations for user's suppliers
    suppliers = Supplier.objects.filter(user_roles__user=request.user, user_roles__is_active=True)
    invitations = SupplierInvitation.objects.filter(supplier__in=suppliers)
    
    return render(request, 'suppliers/invitation_list.html', {'invitations': invitations})


@login_required
@csrf_exempt
@require_http_methods(["POST"])
def send_invitation(request):
    """Send invitation AJAX endpoint"""
    if not isinstance(request.user, SupplierUser):
        return JsonResponse({'error': 'Access denied'}, status=403)
    
    # Check if user is admin
    is_admin = request.user.supplier_roles.filter(is_active=True, role='admin').exists()
    if not is_admin:
        return JsonResponse({'error': 'Admin privileges required'}, status=403)
    
    try:
        data = json.loads(request.body)
        email = data.get('email')
        role = data.get('role', 'staff')
        permissions = data.get('permissions', [])
        
        if not email:
            return JsonResponse({'error': 'Email is required'}, status=400)
        
        # Get supplier
        supplier_role = request.user.supplier_roles.filter(is_active=True).first()
        if not supplier_role:
            return JsonResponse({'error': 'No active supplier role'}, status=400)
        
        # Create invitation
        invitation = SupplierInvitation.objects.create(
            supplier=supplier_role.supplier,
            invited_by=request.user,
            email=email,
            role=role,
            permissions=permissions
        )
        
        # Send invitation email
        invitation.send_invitation_email()
        
        return JsonResponse({
            'message': 'Invitation sent successfully',
            'invitation_id': invitation.id
        })
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=400)
