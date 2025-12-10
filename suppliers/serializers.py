from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from .models import SupplierUser, Supplier, Store, SupplierRole, SupplierInvitation
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer


class SupplierUserSerializer(serializers.ModelSerializer):
    """Serializer for SupplierUser"""
    full_name = serializers.ReadOnlyField()
    
    class Meta:
        model = SupplierUser
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'phone_number', 'is_email_verified', 'is_active',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'is_email_verified', 'created_at', 'updated_at']


class SupplierUserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for supplier user registration"""
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = SupplierUser
        fields = [
            'email', 'first_name', 'last_name', 'phone_number',
            'password', 'password_confirm'
        ]
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = SupplierUser.objects.create_user(**validated_data)
        return user


class SupplierSerializer(serializers.ModelSerializer):
    """Serializer for Supplier"""
    stores_count = serializers.SerializerMethodField()
    users_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Supplier
        fields = [
            'id', 'name', 'slug', 'description', 'contact_person',
            'email', 'phone', 'website', 'address_line1', 'address_line2',
            'city', 'state', 'country', 'postal_code', 'business_license',
            'tax_id', 'status', 'is_active', 'created_at', 'updated_at',
            'approved_at', 'stores_count', 'users_count'
        ]
        read_only_fields = ['id', 'slug', 'created_at', 'updated_at', 'approved_at']
    
    def get_stores_count(self, obj):
        return obj.stores.count()
    
    def get_users_count(self, obj):
        return obj.get_all_users().count()


class StoreSerializer(serializers.ModelSerializer):
    """Serializer for Store"""
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    products_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Store
        fields = [
            'id', 'supplier', 'supplier_name', 'name', 'slug', 'description',
            'store_type', 'currency', 'timezone', 'contact_email', 'contact_phone',
            'address_line1', 'address_line2', 'city', 'state', 'country',
            'postal_code', 'status', 'is_active', 'created_at', 'updated_at',
            'products_count'
        ]
        read_only_fields = ['id', 'slug', 'created_at', 'updated_at']
    
    def get_products_count(self, obj):
        # This would need to be implemented based on your product model
        return 0  # Placeholder


class SupplierRoleSerializer(serializers.ModelSerializer):
    """Serializer for SupplierRole"""
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    accessible_stores_names = serializers.SerializerMethodField()
    
    class Meta:
        model = SupplierRole
        fields = [
            'id', 'user', 'user_email', 'user_full_name', 'supplier', 'supplier_name',
            'role', 'permissions', 'is_active', 'accessible_stores', 'accessible_stores_names',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_accessible_stores_names(self, obj):
        return [store.name for store in obj.accessible_stores.all()]


class SupplierInvitationSerializer(serializers.ModelSerializer):
    """Serializer for SupplierInvitation"""
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    invited_by_name = serializers.CharField(source='invited_by.get_full_name', read_only=True)
    accessible_stores_names = serializers.SerializerMethodField()
    is_expired = serializers.SerializerMethodField()
    
    class Meta:
        model = SupplierInvitation
        fields = [
            'id', 'supplier', 'supplier_name', 'invited_by', 'invited_by_name',
            'email', 'role', 'permissions', 'accessible_stores', 'accessible_stores_names',
            'token', 'status', 'expires_at', 'is_expired', 'created_at', 'updated_at',
            'accepted_at'
        ]
        read_only_fields = [
            'id', 'token', 'status', 'created_at', 'updated_at', 'accepted_at'
        ]
    
    def get_accessible_stores_names(self, obj):
        return [store.name for store in obj.accessible_stores.all()]
    
    def get_is_expired(self, obj):
        return obj.is_expired()


class SupplierInvitationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating supplier invitations"""
    
    class Meta:
        model = SupplierInvitation
        fields = [
            'email', 'role', 'permissions', 'accessible_stores', 'expires_at'
        ]
    
    def create(self, validated_data):
        # Get supplier and invited_by from context
        supplier = self.context['supplier']
        invited_by = self.context['invited_by']
        
        invitation = SupplierInvitation.objects.create(
            supplier=supplier,
            invited_by=invited_by,
            **validated_data
        )
        
        # Send invitation email
        invitation.send_invitation_email()
        
        return invitation


class SupplierLoginSerializer(TokenObtainPairSerializer):
    """Custom login serializer for suppliers"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['email'] = serializers.EmailField()
        self.fields['password'] = serializers.CharField()
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        
        if email and password:
            user = authenticate(username=email, password=password)
            
            if not user:
                raise serializers.ValidationError('Invalid credentials')
            
            if not isinstance(user, SupplierUser):
                raise serializers.ValidationError('User is not a supplier')
            
            if not user.is_active:
                raise serializers.ValidationError('User account is disabled')
            
            # Check if user has any active supplier roles
            if not user.supplier_roles.filter(is_active=True).exists():
                raise serializers.ValidationError('User has no active supplier roles')
            
            attrs['user'] = user
            return attrs
        else:
            raise serializers.ValidationError('Must include "email" and "password"')
    
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        
        # Add custom claims
        token['email'] = user.email
        token['user_type'] = 'supplier'
        
        # Add supplier information
        supplier_roles = user.supplier_roles.filter(is_active=True)
        token['suppliers'] = []
        for role in supplier_roles:
            token['suppliers'].append({
                'id': role.supplier.id,
                'name': role.supplier.name,
                'role': role.role,
                'permissions': role.permissions
            })
        
        return token


class PasswordResetSerializer(serializers.Serializer):
    """Serializer for password reset request"""
    email = serializers.EmailField()
    
    def validate_email(self, value):
        try:
            user = SupplierUser.objects.get(email=value)
            if not user.is_active:
                raise serializers.ValidationError('User account is disabled')
        except SupplierUser.DoesNotExist:
            raise serializers.ValidationError('User with this email does not exist')
        return value


class PasswordResetConfirmSerializer(serializers.Serializer):
    """Serializer for password reset confirmation"""
    token = serializers.UUIDField()
    password = serializers.CharField(validators=[validate_password])
    password_confirm = serializers.CharField()
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs
    
    def validate_token(self, value):
        try:
            user = SupplierUser.objects.get(password_reset_token=value)
            if not user.password_reset_sent_at:
                raise serializers.ValidationError('Invalid token')
            
            # Check if token is expired (24 hours)
            from django.utils import timezone
            from datetime import timedelta
            if timezone.now() > user.password_reset_sent_at + timedelta(hours=24):
                raise serializers.ValidationError('Token has expired')
        except SupplierUser.DoesNotExist:
            raise serializers.ValidationError('Invalid token')
        return value
