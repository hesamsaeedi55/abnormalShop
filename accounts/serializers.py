from rest_framework_simplejwt.serializers import TokenObtainPairSerializer, TokenRefreshSerializer
from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed, ValidationError
from .security_service import LoginSecurityService
from .email_service import SecurityEmailService
import logging

logger = logging.getLogger('security')
Customer = get_user_model()


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Enhanced JWT Token serializer with 5-tier progressive security.
    Implements rate limiting, progressive delays, CAPTCHA, email verification, and account locking.
    """
    username_field = Customer.EMAIL_FIELD
    
    # Add optional fields for security features
    captcha_token = serializers.CharField(required=False, allow_blank=True, write_only=True)
    verification_code = serializers.CharField(required=False, allow_blank=True, write_only=True)
    
    def validate(self, attrs):
        """
        Enhanced validation with complete security checks.
        """
        # Extract email and normalize
        email = attrs.get(self.username_field, '').lower().strip()
        password = attrs.get('password')
        
        # Get request object (passed from view)
        request = self.context.get('request')
        if not request:
            raise ValidationError("Request context required for security checks")
        
        # Initialize security service
        security = LoginSecurityService(request, email)
        
        # ====================================================================
        # STEP 1: Pre-authentication security checks
        # ====================================================================
        security_check = security.check_security()
        
        if not security_check['allowed']:
            # Account is locked or rate limited
            security.record_attempt(
                success=False,
                failure_reason=security_check.get('message', 'rate_limited'),
                security_tier=security_check['tier']
            )
            raise AuthenticationFailed(security_check['message'])
        
        tier = security_check['tier']
        
        # ====================================================================
        # STEP 2: Tier-specific requirements BEFORE authentication
        # ====================================================================
        
        # Tier 3: CAPTCHA Required
        if security_check.get('requires_captcha'):
            captcha_token = attrs.get('captcha_token', '')
            if not captcha_token:
                raise ValidationError({
                    'captcha_required': True,
                    'message': 'Please complete the CAPTCHA verification.'
                })
            
            # TODO: Validate CAPTCHA token with your CAPTCHA service (reCAPTCHA, hCaptcha, etc.)
            # For now, we'll accept any non-empty token as valid
            # In production, integrate with: https://developers.google.com/recaptcha/docs/verify
            if len(captcha_token) < 10:  # Basic validation
                security.record_attempt(
                    success=False,
                    failure_reason='captcha_required',
                    security_tier=tier
                )
                raise ValidationError({
                    'captcha_required': True,
                    'message': 'Invalid CAPTCHA. Please try again.'
                })
        
        # Tier 4: Email Verification Required
        if security_check.get('requires_verification'):
            verification_code = attrs.get('verification_code', '')
            
            if not verification_code:
                # Generate and send code
                code_obj = security.create_verification_code()
                SecurityEmailService.send_verification_code_email(
                    email=email,
                    code=code_obj.code,
                    expires_minutes=10,
                    ip_address=security.ip_address
                )
                
                security.record_attempt(
                    success=False,
                    failure_reason='verification_required',
                    security_tier=tier
                )
                
                raise ValidationError({
                    'verification_required': True,
                    'message': 'Verification code sent to your email. Please enter it to continue.'
                })
            
            # Verify the code
            is_valid, message = security.verify_code(verification_code)
            if not is_valid:
                security.record_attempt(
                    success=False,
                    failure_reason='verification_required',
                    security_tier=tier
                )
                raise ValidationError({
                    'verification_required': True,
                    'message': message
                })
            
            # Code verified successfully - continue to authentication
        
        # ====================================================================
        # STEP 3: Attempt authentication
        # ====================================================================
        try:
            # Call parent class validation (performs actual authentication)
            data = super().validate(attrs)
            
            # Authentication successful!
            security.handle_successful_login()
            
            # Add security context to response
            data['security'] = {
                'tier': tier,
                'message': 'Login successful'
            }
            
            return data
            
        except AuthenticationFailed as e:
            # ================================================================
            # STEP 4: Handle failed authentication
            # ================================================================
            result = security.handle_failed_login(reason='invalid_credentials')
            
            # Tier 5: Lock account
            if result.get('lock_created'):
                lock_token = result.get('unlock_token')
                
                # Send lock email
                from myshop2.myshop.accounts.models import AccountLock
                lock = AccountLock.objects.get(unlock_token=lock_token)
                SecurityEmailService.send_account_locked_email(lock)
                
                raise AuthenticationFailed(result['message'])
            
            # Tier 4: Send verification code
            elif result.get('verification_code_sent'):
                raise ValidationError({
                    'verification_required': True,
                    'message': result['message']
                })
            
            # Tier 3: Send warning email (first time reaching this tier)
            elif result['tier'] == 3:
                # Send warning email once when first hitting tier 3
                attempts_at_tier_3 = result['failed_count']
                if attempts_at_tier_3 == security.SecurityConfig.TIER_2_MAX + 1:  # First tier 3 attempt
                    remaining = security.SecurityConfig.TIER_3_MAX - attempts_at_tier_3
                    SecurityEmailService.send_warning_email(
                        email=email,
                        failed_count=attempts_at_tier_3,
                        remaining_count=remaining,
                        ip_address=security.ip_address
                    )
            
            # Raise authentication error with tier-appropriate message
            raise AuthenticationFailed(result['message'])
    
    @classmethod
    def get_token(cls, user):
        """Add custom claims to token if needed"""
        token = super().get_token(user)
        
        # Add custom claims
        token['email'] = user.email
        token['name'] = user.get_full_name()
        
        return token


class CustomTokenRefreshSerializer(TokenRefreshSerializer):
    """Custom token refresh serializer (can add rate limiting here too if needed)"""
    pass 