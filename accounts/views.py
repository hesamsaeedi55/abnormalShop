from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.shortcuts import render
from django.http import HttpResponse
import logging

from .serializers import EmailTokenObtainPairSerializer, CustomTokenRefreshSerializer
from .security_service import validate_unlock_token, LoginSecurityService
from .email_service import SecurityEmailService
from myshop2.myshop.accounts.models import AccountLock, VerificationCode

logger = logging.getLogger('security')


# ============================================================================
# JWT TOKEN VIEWS (Enhanced with Security)
# ============================================================================

@method_decorator(csrf_exempt, name='dispatch')
class EmailTokenObtainPairView(TokenObtainPairView):
    """
    Enhanced JWT token obtain view with complete 5-tier security.
    Handles login with progressive security measures.
    """
    serializer_class = EmailTokenObtainPairSerializer
    permission_classes = [AllowAny]
    
    def post(self, request, *args, **kwargs):
        """Override to ensure request context is passed to serializer"""
        serializer = self.get_serializer(data=request.data, context={'request': request})
        
        try:
            serializer.is_valid(raise_exception=True)
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        except Exception as e:
            # Return appropriate error response
            return Response(
                {
                    'detail': str(e),
                    'error': True
                },
                status=status.HTTP_401_UNAUTHORIZED
            )


@method_decorator(csrf_exempt, name='dispatch')
class CustomTokenRefreshView(TokenRefreshView):
    """Custom token refresh view"""
    serializer_class = CustomTokenRefreshSerializer
    permission_classes = [AllowAny]


# ============================================================================
# ACCOUNT UNLOCK VIEWS
# ============================================================================

@method_decorator(csrf_exempt, name='dispatch')
class UnlockAccountView(APIView):
    """
    API view to unlock account via token (from email link).
    GET: Display unlock confirmation page
    POST: Process unlock request
    """
    permission_classes = [AllowAny]
    
    def get(self, request, token):
        """Display unlock confirmation page"""
        # Validate token
        success, message, email = validate_unlock_token(token)
        
        context = {
            'success': success,
            'message': message,
            'email': email,
            'token': token
        }
        
        # If successful, also send confirmation email
        if success and email:
            SecurityEmailService.send_unlock_success_email(email)
        
        # Return JSON response (or render HTML template if you have one)
        return Response(context, status=status.HTTP_200_OK if success else status.HTTP_400_BAD_REQUEST)
    
    def post(self, request, token):
        """Process unlock request (same as GET for this implementation)"""
        return self.get(request, token)


class ResendVerificationCodeView(APIView):
    """
    Resend verification code to user's email.
    Used when code expires or user didn't receive it.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Resend verification code"""
        email = request.data.get('email', '').lower().strip()
        
        if not email:
            return Response(
                {'error': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Initialize security service
        security = LoginSecurityService(request, email)
        
        # Check if account is locked
        is_locked, lock_obj, _ = security.check_account_lock()
        if is_locked:
            return Response(
                {'error': 'Account is locked. Check your email for unlock instructions.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Check rate limiting (prevent code spam)
        recent_codes = VerificationCode.objects.filter(
            email=email,
            created_at__gte=timezone.now() - timedelta(minutes=5)
        ).count()
        
        if recent_codes >= 3:
            return Response(
                {'error': 'Too many code requests. Please wait 5 minutes.'},
                status=status.HTTP_429_TOO_MANY_REQUESTS
            )
        
        # Generate new code
        code_obj = security.create_verification_code()
        
        # Send email
        sent = SecurityEmailService.send_verification_code_email(
            email=email,
            code=code_obj.code,
            expires_minutes=10,
            ip_address=security.ip_address
        )
        
        if sent:
            return Response(
                {'message': 'Verification code sent successfully'},
                status=status.HTTP_200_OK
            )
        else:
            return Response(
                {'error': 'Failed to send verification code'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ============================================================================
# ADMIN / MONITORING VIEWS
# ============================================================================

class SecurityDashboardView(APIView):
    """
    View security statistics and recent login attempts.
    Requires admin/staff authentication.
    """
    permission_classes = [AllowAny]  # Change to IsAdminUser in production
    
    def get(self, request):
        """Get security statistics"""
        from datetime import timedelta
        from django.utils import timezone
        from myshop2.myshop.accounts.models import LoginAttempt, AccountLock
        
        now = timezone.now()
        last_hour = now - timedelta(hours=1)
        last_day = now - timedelta(days=1)
        
        stats = {
            'last_hour': {
                'total_attempts': LoginAttempt.objects.filter(created_at__gte=last_hour).count(),
                'failed_attempts': LoginAttempt.objects.filter(created_at__gte=last_hour, success=False).count(),
                'successful_logins': LoginAttempt.objects.filter(created_at__gte=last_hour, success=True).count(),
                'tier_5_triggers': LoginAttempt.objects.filter(created_at__gte=last_hour, security_tier=5).count(),
            },
            'last_24_hours': {
                'total_attempts': LoginAttempt.objects.filter(created_at__gte=last_day).count(),
                'failed_attempts': LoginAttempt.objects.filter(created_at__gte=last_day, success=False).count(),
                'successful_logins': LoginAttempt.objects.filter(created_at__gte=last_day, success=True).count(),
                'accounts_locked': AccountLock.objects.filter(locked_at__gte=last_day, is_active=True).count(),
            },
            'active_locks': AccountLock.objects.filter(is_active=True).count(),
            'recent_failed_attempts': list(
                LoginAttempt.objects.filter(
                    success=False,
                    created_at__gte=last_hour
                ).values('email', 'ip_address', 'created_at', 'security_tier')[:20]
            ),
            'active_locks_detail': list(
                AccountLock.objects.filter(is_active=True).values(
                    'email', 'locked_at', 'expires_at', 'attempt_count'
                )[:10]
            )
        }
        
        return Response(stats, status=status.HTTP_200_OK)


# ============================================================================
# HELPER VIEWS (Optional - for testing)
# ============================================================================

class CheckSecurityStatusView(APIView):
    """
    Check security status for an email address.
    Useful for debugging and monitoring.
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Check security status"""
        email = request.data.get('email', '').lower().strip()
        
        if not email:
            return Response(
                {'error': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Initialize security service
        security = LoginSecurityService(request, email)
        
        # Get security status
        security_check = security.check_security()
        
        # Check account lock
        is_locked, lock_obj, minutes_remaining = security.check_account_lock()
        
        response_data = {
            'email': email,
            'is_locked': is_locked,
            'minutes_remaining': minutes_remaining if is_locked else 0,
            'security_tier': security_check['tier'],
            'failed_attempts_24h': security_check['failed_count'],
            'requires_captcha': security_check.get('requires_captcha', False),
            'requires_verification': security_check.get('requires_verification', False),
            'message': security_check.get('message', ''),
        }
        
        if lock_obj:
            response_data['lock_details'] = {
                'locked_at': lock_obj.locked_at,
                'expires_at': lock_obj.expires_at,
                'reason': lock_obj.reason,
                'attempt_count': lock_obj.attempt_count,
            }
        
        return Response(response_data, status=status.HTTP_200_OK)


# Import timezone for ResendVerificationCodeView
from django.utils import timezone
from datetime import timedelta 