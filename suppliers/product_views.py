from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.core.exceptions import ValidationError
from django.db.models import Q, Count, Sum
from django.utils import timezone
from datetime import timedelta

from suppliers.models import SupplierUser, Supplier, Store, SupplierRole
from suppliers.permissions import IsSupplierUser, CanManageProducts, CanManageInventory
from shop.models import Product, ProductVariant, ProductImage, Category, Tag
from shop.serializers import ProductSerializer, CategorySerializer
from .product_serializers import (
    SupplierProductSerializer, SupplierProductCreateSerializer,
    SupplierProductVariantSerializer, SupplierProductVariantCreateSerializer,
    SupplierProductImageSerializer, SupplierProductImageCreateSerializer,
    SupplierProductStatsSerializer
)


class SupplierProductListView(generics.ListCreateAPIView):
    """List and create products for authenticated supplier"""
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return SupplierProductCreateSerializer
        return SupplierProductSerializer
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return Product.objects.filter(supplier__in=suppliers).select_related('category', 'supplier').prefetch_related('variants', 'images')
    
    def perform_create(self, serializer):
        # Get the supplier from user's roles
        user = self.request.user
        supplier_role = user.supplier_roles.filter(is_active=True).first()
        if not supplier_role:
            raise ValidationError('User has no active supplier roles')
        
        # Check if user has permission to manage products
        if not supplier_role.has_permission('manage_products'):
            raise ValidationError('User does not have permission to manage products')
        
        serializer.save(supplier=supplier_role.supplier)


class SupplierProductDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Product detail management for suppliers"""
    serializer_class = SupplierProductSerializer
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return Product.objects.filter(supplier__in=suppliers).select_related('category', 'supplier').prefetch_related('variants', 'images')


class SupplierProductVariantListView(generics.ListCreateAPIView):
    """List and create product variants for authenticated supplier"""
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return SupplierProductVariantCreateSerializer
        return SupplierProductVariantSerializer
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return ProductVariant.objects.filter(product__supplier__in=suppliers).select_related('product')
    
    def perform_create(self, serializer):
        # Get the supplier from user's roles
        user = self.request.user
        supplier_role = user.supplier_roles.filter(is_active=True).first()
        if not supplier_role:
            raise ValidationError('User has no active supplier roles')
        
        # Check if user has permission to manage products
        if not supplier_role.has_permission('manage_products'):
            raise ValidationError('User does not have permission to manage products')
        
        # Verify the product belongs to the supplier
        product = serializer.validated_data['product']
        if product.supplier != supplier_role.supplier:
            raise ValidationError('Product does not belong to your supplier')
        
        serializer.save()


class SupplierProductVariantDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Product variant detail management for suppliers"""
    serializer_class = SupplierProductVariantSerializer
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return ProductVariant.objects.filter(product__supplier__in=suppliers).select_related('product')


class SupplierProductImageListView(generics.ListCreateAPIView):
    """List and create product images for authenticated supplier"""
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return SupplierProductImageCreateSerializer
        return SupplierProductImageSerializer
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return ProductImage.objects.filter(product__supplier__in=suppliers).select_related('product')
    
    def perform_create(self, serializer):
        # Get the supplier from user's roles
        user = self.request.user
        supplier_role = user.supplier_roles.filter(is_active=True).first()
        if not supplier_role:
            raise ValidationError('User has no active supplier roles')
        
        # Check if user has permission to manage products
        if not supplier_role.has_permission('manage_products'):
            raise ValidationError('User does not have permission to manage products')
        
        # Verify the product belongs to the supplier
        product = serializer.validated_data['product']
        if product.supplier != supplier_role.supplier:
            raise ValidationError('Product does not belong to your supplier')
        
        serializer.save()


class SupplierProductImageDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Product image detail management for suppliers"""
    serializer_class = SupplierProductImageSerializer
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        return ProductImage.objects.filter(product__supplier__in=suppliers).select_related('product')


class SupplierProductStatsView(APIView):
    """Product statistics for suppliers"""
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def get(self, request):
        user = request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        
        stats = {
            'total_products': 0,
            'active_products': 0,
            'draft_products': 0,
            'low_stock_products': 0,
            'out_of_stock_products': 0,
            'total_variants': 0,
            'low_stock_variants': 0,
            'out_of_stock_variants': 0,
            'suppliers': []
        }
        
        for supplier in suppliers:
            products = Product.objects.filter(supplier=supplier)
            variants = ProductVariant.objects.filter(product__supplier=supplier)
            
            supplier_stats = {
                'id': supplier.id,
                'name': supplier.name,
                'total_products': products.count(),
                'active_products': products.filter(is_active=True).count(),
                'draft_products': products.filter(is_active=False).count(),
                'low_stock_products': products.filter(stock_quantity__lt=10, stock_quantity__gt=0).count(),
                'out_of_stock_products': products.filter(stock_quantity=0).count(),
                'total_variants': variants.count(),
                'low_stock_variants': variants.filter(stock_quantity__lt=10, stock_quantity__gt=0).count(),
                'out_of_stock_variants': variants.filter(stock_quantity=0).count(),
            }
            
            stats['suppliers'].append(supplier_stats)
            stats['total_products'] += supplier_stats['total_products']
            stats['active_products'] += supplier_stats['active_products']
            stats['draft_products'] += supplier_stats['draft_products']
            stats['low_stock_products'] += supplier_stats['low_stock_products']
            stats['out_of_stock_products'] += supplier_stats['out_of_stock_products']
            stats['total_variants'] += supplier_stats['total_variants']
            stats['low_stock_variants'] += supplier_stats['low_stock_variants']
            stats['out_of_stock_variants'] += supplier_stats['out_of_stock_variants']
        
        return Response(stats)


class SupplierLowStockProductsView(generics.ListAPIView):
    """List products with low stock for suppliers"""
    serializer_class = SupplierProductSerializer
    permission_classes = [IsSupplierUser, CanManageInventory]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        
        # Get threshold from query params
        threshold = int(self.request.query_params.get('threshold', 10))
        
        return Product.objects.filter(
            supplier__in=suppliers,
            stock_quantity__lt=threshold,
            stock_quantity__gt=0,
            is_active=True
        ).select_related('category', 'supplier').prefetch_related('variants', 'images')


class SupplierOutOfStockProductsView(generics.ListAPIView):
    """List out of stock products for suppliers"""
    serializer_class = SupplierProductSerializer
    permission_classes = [IsSupplierUser, CanManageInventory]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        
        return Product.objects.filter(
            supplier__in=suppliers,
            stock_quantity=0,
            is_active=True
        ).select_related('category', 'supplier').prefetch_related('variants', 'images')


class SupplierProductBulkUpdateView(APIView):
    """Bulk update products for suppliers"""
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def post(self, request):
        user = request.user
        supplier_role = user.supplier_roles.filter(is_active=True).first()
        if not supplier_role:
            return Response({'error': 'User has no active supplier roles'}, status=status.HTTP_400_BAD_REQUEST)
        
        if not supplier_role.has_permission('manage_products'):
            return Response({'error': 'User does not have permission to manage products'}, status=status.HTTP_403_FORBIDDEN)
        
        product_ids = request.data.get('product_ids', [])
        updates = request.data.get('updates', {})
        
        if not product_ids or not updates:
            return Response({'error': 'product_ids and updates are required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            with transaction.atomic():
                products = Product.objects.filter(
                    id__in=product_ids,
                    supplier=supplier_role.supplier
                )
                
                updated_count = products.update(**updates)
                
                return Response({
                    'message': f'Successfully updated {updated_count} products',
                    'updated_count': updated_count
                })
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


class SupplierProductSearchView(generics.ListAPIView):
    """Search products for suppliers"""
    serializer_class = SupplierProductSerializer
    permission_classes = [IsSupplierUser, CanManageProducts]
    
    def get_queryset(self):
        user = self.request.user
        suppliers = Supplier.objects.filter(user_roles__user=user, user_roles__is_active=True)
        
        queryset = Product.objects.filter(supplier__in=suppliers).select_related('category', 'supplier').prefetch_related('variants', 'images')
        
        # Search parameters
        search = self.request.query_params.get('search')
        category_id = self.request.query_params.get('category')
        is_active = self.request.query_params.get('is_active')
        low_stock = self.request.query_params.get('low_stock')
        
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) |
                Q(description__icontains=search) |
                Q(sku__icontains=search) |
                Q(model__icontains=search)
            )
        
        if category_id:
            queryset = queryset.filter(category_id=category_id)
        
        if is_active is not None:
            queryset = queryset.filter(is_active=is_active.lower() == 'true')
        
        if low_stock is not None and low_stock.lower() == 'true':
            queryset = queryset.filter(stock_quantity__lt=10, stock_quantity__gt=0)
        
        return queryset
