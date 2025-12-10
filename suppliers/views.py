from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from django.db import transaction
from django.core.exceptions import ValidationError
from django.shortcuts import get_object_or_404
from django.utils.crypto import get_random_string
import uuid

from .models import SupplierUser, Supplier, Store, SupplierRole, SupplierInvitation
from .serializers import (
    SupplierUserSerializer, SupplierUserRegistrationSerializer,
    SupplierSerializer, StoreSerializer, SupplierRoleSerializer,
    SupplierInvitationSerializer, SupplierInvitationCreateSerializer,
    SupplierLoginSerializer, PasswordResetSerializer, PasswordResetConfirmSerializer
)
from .permissions import IsSupplierUser, IsSupplierAdmin, IsSupplierStaff, CanManageStore


class SupplierLoginView(APIView):
    """Login endpoint for suppliers"""
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = SupplierLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            tokens = serializer.get_token(user)
            
            return Response({
                'access': str(tokens.access_token),
                'refresh': str(tokens.refresh_token),
                'user': SupplierUserSerializer(user).data
            })
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SupplierRegistrationView(generics.CreateAPIView):
    """Registration endpoint for suppliers"""
    serializer_class = SupplierUserRegistrationSerializer
    permission_classes = [permissions.AllowAny]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            # Send email verification
            user.generate_email_verification_token()
            # TODO: Send verification email
            
            return Response({
                'message': 'Registration successful. Please check your email for verification.',
                'user': SupplierUserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetView(APIView):
    """Password reset request endpoint"""
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = PasswordResetSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            user = SupplierUser.objects.get(email=email)
            
            # Generate reset token
            user.password_reset_token = uuid.uuid4()
            user.password_reset_sent_at = timezone.now()
            user.save()
            
            # Send reset email
            subject = 'Password Reset Request'
            message = f"""
            You requested a password reset for your supplier account.
            
            Click the link below to reset your password:
            {settings.FRONTEND_URL}/suppliers/reset-password/{user.password_reset_token}/
            
            This link expires in 24 hours.
            """
            
            send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [email])
            
            return Response({'message': 'Password reset email sent'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetConfirmView(APIView):
    """Password reset confirmation endpoint"""
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            token = serializer.validated_data['token']
            password = serializer.validated_data['password']
            
            user = SupplierUser.objects.get(password_reset_token=token)
            user.set_password(password)
            user.password_reset_token = None
            user.password_reset_sent_at = None
            user.save()
            
            return Response({'message': 'Password reset successful'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SupplierProfileView(generics.RetrieveUpdateAPIView):
    """Supplier user profile management"""
    serializer_class = SupplierUserSerializer
    permission_classes = [IsSupplierUser]
    
    def get_object(self):
        return self.request.user


class SupplierListView(generics.ListCreateAPIView):
    """List and create suppliers (admin only)"""
    serializer_class = SupplierSerializer
    permission_classes = [permissions.IsAdminUser]
    queryset = Supplier.objects.all()


class SupplierDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Supplier detail management"""
    serializer_class = SupplierSerializer
    permission_classes = [permissions.IsAdminUser]
    queryset = Supplier.objects.all()


class StoreListView(generics.ListCreateAPIView):
    """List and create stores for authenticated supplier"""
    serializer_class = StoreSerializer
    permission_classes = [IsSupplierUser]
    
    def get_queryset(self):
        user = self.request.user
        # Get stores from all suppliers the user has access to
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return Store.objects.filter(supplier__in=suppliers)
    
    def perform_create(self, serializer):
        # Get the supplier from user's roles
        user = self.request.user
        supplier_role = user.supplier_roles.filter(is_active=True).first()
        if not supplier_role:
            raise ValidationError('User has no active supplier roles')
        
        # Check if user has permission to manage stores
        if not supplier_role.has_permission('manage_stores'):
            raise ValidationError('User does not have permission to manage stores')
        
        serializer.save(supplier=supplier_role.supplier)


class StoreDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Store detail management"""
    serializer_class = StoreSerializer
    permission_classes = [IsSupplierUser, CanManageStore]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return Store.objects.filter(supplier__in=suppliers)


class SupplierRoleListView(generics.ListCreateAPIView):
    """List and create supplier roles"""
    serializer_class = SupplierRoleSerializer
    permission_classes = [IsSupplierAdmin]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return SupplierRole.objects.filter(supplier__in=suppliers)
    
    def perform_create(self, serializer):
        # Get the supplier from user's roles
        user = self.request.user
        supplier_role = user.supplier_roles.filter(is_active=True).first()
        if not supplier_role:
            raise ValidationError('User has no active supplier roles')
        
        serializer.save(supplier=supplier_role.supplier)


class SupplierRoleDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Supplier role detail management"""
    serializer_class = SupplierRoleSerializer
    permission_classes = [IsSupplierAdmin]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return SupplierRole.objects.filter(supplier__in=suppliers)


class SupplierInvitationListView(generics.ListCreateAPIView):
    """List and create supplier invitations"""
    permission_classes = [IsSupplierAdmin]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return SupplierInvitationCreateSerializer
        return SupplierInvitationSerializer
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return SupplierInvitation.objects.filter(supplier__in=suppliers)
    
    def perform_create(self, serializer):
        # Get the supplier from user's roles
        user = self.request.user
        supplier_role = user.supplier_roles.filter(is_active=True).first()
        if not supplier_role:
            raise ValidationError('User has no active supplier roles')
        
        serializer.save(
            supplier=supplier_role.supplier,
            invited_by=user
        )


class SupplierInvitationDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Supplier invitation detail management"""
    serializer_class = SupplierInvitationSerializer
    permission_classes = [IsSupplierAdmin]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return SupplierInvitation.objects.filter(supplier__in=suppliers)


class AcceptInvitationView(APIView):
    """Accept supplier invitation"""
    permission_classes = [permissions.AllowAny]
    
    def post(self, request, token):
        try:
            invitation = SupplierInvitation.objects.get(token=token)
        except SupplierInvitation.DoesNotExist:
            return Response({'error': 'Invalid invitation token'}, status=status.HTTP_400_BAD_REQUEST)
        
        if invitation.status != 'pending':
            return Response({'error': 'Invitation is not pending'}, status=status.HTTP_400_BAD_REQUEST)
        
        if invitation.is_expired():
            return Response({'error': 'Invitation has expired'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user exists
        email = invitation.email
        try:
            user = SupplierUser.objects.get(email=email)
        except SupplierUser.DoesNotExist:
            return Response({'error': 'User does not exist'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Accept invitation
        try:
            role = invitation.accept_invitation(user)
            return Response({
                'message': 'Invitation accepted successfully',
                'role': SupplierRoleSerializer(role).data
            })
        except ValidationError as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class SupplierDashboardView(APIView):
    """Supplier dashboard with analytics"""
    permission_classes = [IsSupplierUser]
    
    def get(self, request):
        user = request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        
        dashboard_data = {
            'suppliers': [],
            'total_stores': 0,
            'total_products': 0,
            'total_orders': 0,
            'pending_orders': 0,
            'low_stock_alerts': 0
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
            
            dashboard_data['suppliers'].append(supplier_data)
            dashboard_data['total_stores'] += supplier_data['stores_count']
            dashboard_data['total_products'] += supplier_data['products_count']
            dashboard_data['total_orders'] += supplier_data['orders_count']
            dashboard_data['pending_orders'] += supplier_data['pending_orders_count']
            dashboard_data['low_stock_alerts'] += supplier_data['low_stock_count']
        
        return Response(dashboard_data)


class StoreDashboardView(APIView):
    """Store-specific dashboard"""
    permission_classes = [IsSupplierUser, CanManageStore]
    
    def get(self, request, store_id):
        store = get_object_or_404(Store, id=store_id)
        
        # Check if user has access to this store
        user = request.user
        has_access = False
        for role in user.supplier_roles.filter(is_active=True):
            if role.can_access_store(store):
                has_access = True
                break
        
        if not has_access:
            return Response({'error': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)
        
        dashboard_data = {
            'store': StoreSerializer(store).data,
            'products_count': 0,  # TODO: Implement product counting
            'orders_count': 0,    # TODO: Implement order counting
            'pending_orders_count': 0,  # TODO: Implement pending orders counting
            'low_stock_count': 0,  # TODO: Implement low stock counting
            'recent_orders': [],   # TODO: Implement recent orders
            'low_stock_products': []  # TODO: Implement low stock products
        }
        
        return Response(dashboard_data)
