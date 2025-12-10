"""
URL routing for accounts app with complete security endpoints
"""
from django.urls import path
from .views import (
    EmailTokenObtainPairView,
    CustomTokenRefreshView,
    UnlockAccountView,
    ResendVerificationCodeView,
    SecurityDashboardView,
    CheckSecurityStatusView,
)

app_name = 'accounts'

urlpatterns = [
    # ========================================================================
    # JWT AUTHENTICATION ENDPOINTS
    # ========================================================================
    
    # Main login endpoint (with 5-tier security)
    path('token/', EmailTokenObtainPairView.as_view(), name='token_obtain_pair'),
    
    # Token refresh
    path('token/refresh/', CustomTokenRefreshView.as_view(), name='token_refresh'),
    
    # ========================================================================
    # SECURITY UNLOCK & VERIFICATION ENDPOINTS
    # ========================================================================
    
    # Unlock account via email link
    # Example: /accounts/unlock/abc123xyz...
    path('unlock/<str:token>/', UnlockAccountView.as_view(), name='unlock_account'),
    
    # Resend verification code (Tier 4)
    path('resend-code/', ResendVerificationCodeView.as_view(), name='resend_verification_code'),
    
    # Check security status for an email (debugging/monitoring)
    path('security/status/', CheckSecurityStatusView.as_view(), name='security_status'),
    
    # ========================================================================
    # ADMIN / MONITORING ENDPOINTS
    # ========================================================================
    
    # Security dashboard with statistics
    path('security/dashboard/', SecurityDashboardView.as_view(), name='security_dashboard'),
]

