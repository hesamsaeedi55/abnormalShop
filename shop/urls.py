from django.urls import path
from . import views
from .api_views import (
    api_categories_with_gender,
    api_products_by_gender_category,
    api_products_with_variants,
    api_product_variants,
    api_variants_by_attributes,
    api_orders_list,
    api_orders_detail,
    api_orders_update_paid,
    api_orders_export_csv,
)

urlpatterns = [
    # ... existing urls ...
    path('api/categories/', api_categories_with_gender, name='api_categories_gender'),
    path('api/products/', api_products_by_gender_category, name='api_products_gender'),
    
    # Product Variants API endpoints
    path('api/products-with-variants/', api_products_with_variants, name='api_products_with_variants'),
    path('api/products/<int:product_id>/variants/', api_product_variants, name='api_product_variants'),
    path('api/variants/', api_variants_by_attributes, name='api_variants_by_attributes'),
    
    # Orders
    path('api/orders/', api_orders_list, name='api_orders_list'),
    path('api/orders/export/csv/', api_orders_export_csv, name='api_orders_export_csv'),
    path('api/orders/<int:order_id>/', api_orders_detail, name='api_orders_detail'),
    path('api/orders/<int:order_id>/paid/', api_orders_update_paid, name='api_orders_update_paid'),
    # ... existing urls ...
] 