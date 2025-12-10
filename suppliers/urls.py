from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from . import product_views
from . import web_views

# Create router for API views
router = DefaultRouter()

urlpatterns = [
    # Authentication endpoints
    path('auth/login/', views.SupplierLoginView.as_view(), name='supplier-login'),
    path('auth/register/', views.SupplierRegistrationView.as_view(), name='supplier-register'),
    path('auth/password-reset/', views.PasswordResetView.as_view(), name='password-reset'),
    path('auth/password-reset-confirm/', views.PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    
    # Profile management
    path('profile/', views.SupplierProfileView.as_view(), name='supplier-profile'),
    
    # Supplier management (admin only)
    path('suppliers/', views.SupplierListView.as_view(), name='supplier-list'),
    path('suppliers/<int:pk>/', views.SupplierDetailView.as_view(), name='supplier-detail'),
    
    # Store management
    path('stores/', views.StoreListView.as_view(), name='store-list'),
    path('stores/<int:pk>/', views.StoreDetailView.as_view(), name='store-detail'),
    
    # Role management
    path('roles/', views.SupplierRoleListView.as_view(), name='role-list'),
    path('roles/<int:pk>/', views.SupplierRoleDetailView.as_view(), name='role-detail'),
    
    # Invitation management
    path('invitations/', views.SupplierInvitationListView.as_view(), name='invitation-list'),
    path('invitations/<int:pk>/', views.SupplierInvitationDetailView.as_view(), name='invitation-detail'),
    path('invitations/accept/<uuid:token>/', views.AcceptInvitationView.as_view(), name='accept-invitation'),
    
    # Dashboard and analytics
    path('dashboard/', views.SupplierDashboardView.as_view(), name='supplier-dashboard'),
    path('stores/<int:store_id>/dashboard/', views.StoreDashboardView.as_view(), name='store-dashboard'),
    
    # Product management
    path('products/', product_views.SupplierProductListView.as_view(), name='supplier-product-list'),
    path('products/<int:pk>/', product_views.SupplierProductDetailView.as_view(), name='supplier-product-detail'),
    path('products/stats/', product_views.SupplierProductStatsView.as_view(), name='supplier-product-stats'),
    path('products/low-stock/', product_views.SupplierLowStockProductsView.as_view(), name='supplier-low-stock-products'),
    path('products/out-of-stock/', product_views.SupplierOutOfStockProductsView.as_view(), name='supplier-out-of-stock-products'),
    path('products/bulk-update/', product_views.SupplierProductBulkUpdateView.as_view(), name='supplier-product-bulk-update'),
    path('products/search/', product_views.SupplierProductSearchView.as_view(), name='supplier-product-search'),
    
    # Product variants
    path('variants/', product_views.SupplierProductVariantListView.as_view(), name='supplier-variant-list'),
    path('variants/<int:pk>/', product_views.SupplierProductVariantDetailView.as_view(), name='supplier-variant-detail'),
    
    # Product images
    path('images/', product_views.SupplierProductImageListView.as_view(), name='supplier-image-list'),
    path('images/<int:pk>/', product_views.SupplierProductImageDetailView.as_view(), name='supplier-image-detail'),
    
    # Web interface
    path('web/', web_views.supplier_landing, name='supplier-landing'),
    path('web/login/', web_views.supplier_login, name='supplier-login'),
    path('web/logout/', web_views.supplier_logout, name='supplier-logout'),
    path('web/dashboard/', web_views.supplier_dashboard, name='supplier-dashboard'),
    path('web/profile/', web_views.supplier_profile, name='supplier-profile'),
    path('web/stores/', web_views.store_list, name='store-list'),
    path('web/stores/<int:store_id>/', web_views.store_detail, name='store-detail'),
    path('web/roles/', web_views.role_list, name='role-list'),
    path('web/invitations/', web_views.invitation_list, name='invitation-list'),
    path('web/send-invitation/', web_views.send_invitation, name='send-invitation'),
]

# Include router URLs
urlpatterns += router.urls
