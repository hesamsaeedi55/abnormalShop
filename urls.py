from django.urls import path
from . import views

urlpatterns = [
    # ... existing URLs ...
    # path('auth/google', views.google_auth_view, name='google_auth'),
    path('token/refresh/', views.refresh_token_view, name='token_refresh'),
    path('admin/baskets/', views.admin_baskets_view, name='admin_baskets'),
] 