from django.db.models import Q, Count
from django.core.paginator import Paginator
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone

# Import Product from the primary shop app (inside myshop project)
try:
    # Typical path when the inner project app label is `shop` inside project `myshop`
    from myshop.shop.models import Product, Category, AttributeValue, Order, OrderItem, ProductVariant
except Exception:
    # Fallback: if models are accessible differently, attempt local names (won't break existing endpoints)
    Product = None
    Category = None
    AttributeValue = None
    Order = None
    OrderItem = None
    ProductVariant = None

@api_view(['GET'])
def api_categories_with_gender(request):
    """
    Get category structure with gender subcategories
    URL: /api/categories/
    """
    try:
        # Get main categories (no parent)
        main_categories = Category.objects.filter(parent=None).prefetch_related('subcategories')
        
        categories_data = []
        for category in main_categories:
            category_data = {
                'id': category.id,
                'name': category.name,
                'parent_id': None,
                'subcategories': []
            }
            
            # Get subcategories with gender information
            for subcategory in category.subcategories.all():
                gender = extract_gender_from_category_name(subcategory.name)
                subcategory_data = {
                    'id': subcategory.id,
                    'name': subcategory.name,
                    'parent_id': category.id,
                    'gender': gender,
                    'product_count': subcategory.product_set.filter(is_active=True).count()
                }
                category_data['subcategories'].append(subcategory_data)
            
            # Only include categories that have subcategories or products
            if category_data['subcategories'] or category.product_set.filter(is_active=True).exists():
                categories_data.append(category_data)
        
        return Response({
            'success': True,
            'categories': categories_data
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=500)

@api_view(['GET'])
def api_products_by_gender_category(request):
    """
    Get products filtered by category and/or gender
    URL: /api/products/
    Parameters:
        - category: Category name (e.g., 'ساعت')
        - gender: Gender filter ('مردانه', 'زنانه', 'یونیسکس')
        - page: Page number for pagination
        - limit: Items per page (default: 20)
    """
    try:
        category_name = request.GET.get('category')
        gender = request.GET.get('gender')
        page = int(request.GET.get('page', 1))
        limit = int(request.GET.get('limit', 20))
        search_query = request.GET.get('search', '')
        
        # Start with active products
        products = Product.objects.filter(is_active=True)
        
        # Apply category filter
        if category_name:
            # Method 1: Try gender-specific category first
            if gender:
                gender_category_name = f"{category_name} {gender}"
                gender_category = Category.objects.filter(name=gender_category_name).first()
                if gender_category:
                    products = products.filter(category=gender_category)
                else:
                    # Fallback to attribute-based filtering
                    products = filter_by_category_and_gender_attribute(products, category_name, gender)
            else:
                # Get all products from main category and its subcategories
                main_category = Category.objects.filter(name=category_name).first()
                if main_category:
                    all_subcategories = [main_category] + main_category.get_all_subcategories()
                    products = products.filter(category__in=all_subcategories)
        
        # Apply search filter
        if search_query:
            products = products.filter(
                Q(name__icontains=search_query) |
                Q(description__icontains=search_query) |
                Q(model__icontains=search_query)
            )
        
        # Order by creation date (newest first)
        products = products.order_by('-created_at')
        
        # Paginate results
        paginator = Paginator(products, limit)
        page_obj = paginator.get_page(page)
        
        # Serialize products
        products_data = []
        for product in page_obj:
            # Get gender from attributes or category name
            product_gender = get_product_gender(product)
            
            product_data = {
                'id': product.id,
                'name': product.name,
                'price': float(product.price_toman),
                'price_usd': float(product.price_usd) if product.price_usd else None,
                'description': product.description,
                'category_id': product.category.id,
                'category_name': product.category.name,
                'gender': product_gender,
                'image_url': get_product_image_url(product),
                'attributes': get_product_attributes(product),
                'created_at': product.created_at.isoformat(),
                'supplier': product.supplier.name if product.supplier else None
            }
            products_data.append(product_data)
        
        return Response({
            'success': True,
            'products': products_data,
            'pagination': {
                'page': page,
                'total_pages': paginator.num_pages,
                'total_items': paginator.count,
                'has_next': page_obj.has_next(),
                'has_previous': page_obj.has_previous()
            },
            'filters': {
                'category': category_name,
                'gender': gender,
                'search': search_query
            }
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=500)

@api_view(['GET'])
def dynamic_attribute_values(request, category_id):
    try:
        category = Category.objects.get(id=category_id)
        attribute_key = request.GET.get('attribute_key', 'brand')  # Default to 'brand' or make it dynamic
        
        # Query attribute values for the category (adjust based on your models)
        values = AttributeValue.objects.filter(
            product__category=category,
            attribute__key=attribute_key
        ).values_list('value', flat=True).distinct()  # Fetch distinct values
        
        return Response({
            'category': {
                'id': category.id,
                'name': category.name
            },
            'attribute_key': attribute_key,
            'values': list(values),  # Convert to list for JSON response
            'pagination': {
                'current_page': 1,
                'total_pages': 1,
                'total_items': len(values),
                'has_next': False,
                'has_previous': False
            }
        })
    except Category.DoesNotExist:
        return Response({'error': 'Category not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

# Helper Functions
def extract_gender_from_category_name(category_name):
    """Extract gender from category name"""
    if 'مردانه' in category_name:
        return 'مردانه'
    elif 'زنانه' in category_name:
        return 'زنانه'
    elif 'یونیسکس' in category_name:
        return 'یونیسکس'
    return None

def get_product_gender(product):
    """Get product gender from attributes or category name"""
    # First try to get from attributes
    try:
        gender_attr = product.attribute_values.filter(
            attribute__key='جنسیت'
        ).first()
        if gender_attr:
            if gender_attr.attribute_value:
                return gender_attr.attribute_value.value
            return gender_attr.custom_value
    except:
        pass
    
    # Fallback to category name
    return extract_gender_from_category_name(product.category.name)

def get_product_image_url(product):
    """Get product image URL"""
    try:
        # Assuming you have a ProductImage model
        first_image = product.productimage_set.first()
        if first_image and first_image.image:
            return first_image.image.url
    except:
        pass
    return None

def get_product_attributes(product):
    """Get product attributes as a list"""
    attributes = []
    try:
        for attr_value in product.attribute_values.all():
            attributes.append({
                'key': attr_value.attribute.key,
                'value': attr_value.get_display_value(),
                'display_name': attr_value.attribute.name
            })
        
        # Add brand attribute if it exists
        if product.brand:
            attributes.append({
                'key': 'brand',
                'value': product.brand.name,  # Assuming brand has a name field
                'display_name': 'Brand'
            })
    except:
        pass
    return attributes

def filter_by_category_and_gender_attribute(products, category_name, gender):
    """Filter products by category and gender using attributes"""
    # Get main category
    main_category = Category.objects.filter(name=category_name).first()
    if not main_category:
        return products.none()
    
    # Get all subcategories
    all_subcategories = [main_category] + main_category.get_all_subcategories()
    
    # Filter by category and gender attribute
        return products.filter(
        category__in=all_subcategories,
        attribute_values__attribute__key='جنسیت',
        attribute_values__attribute_value__value=gender
    ).distinct()


# ========================================
# PRODUCT VARIANTS API ENDPOINTS
# ========================================

@api_view(['GET'])
def api_products_with_variants(request):
    """
    Get products with their variants
    URL: /api/products-with-variants/
    Parameters:
        - category: Category name (e.g., 'ساعت')
        - gender: Gender filter ('مردانه', 'زنانه', 'یونیسکس')
        - page: Page number for pagination
        - limit: Items per page (default: 20)
        - search: Search query
    """
    try:
        category_name = request.GET.get('category')
        gender = request.GET.get('gender')
        page = int(request.GET.get('page', 1))
        limit = int(request.GET.get('limit', 20))
        search_query = request.GET.get('search', '')
        
        # Start with active products that have variants
        products = Product.objects.filter(is_active=True, variants__isnull=False).distinct()
        
        # Apply category filter
        if category_name:
            if gender:
                gender_category_name = f"{category_name} {gender}"
                gender_category = Category.objects.filter(name=gender_category_name).first()
                if gender_category:
                    products = products.filter(category=gender_category)
                else:
                    products = filter_by_category_and_gender_attribute(products, category_name, gender)
            else:
                main_category = Category.objects.filter(name=category_name).first()
                if main_category:
                    all_subcategories = [main_category] + main_category.get_all_subcategories()
                    products = products.filter(category__in=all_subcategories)
        
        # Apply search filter
        if search_query:
            products = products.filter(
                Q(name__icontains=search_query) |
                Q(description__icontains=search_query) |
                Q(model__icontains=search_query)
            )
        
        # Order by creation date (newest first)
        products = products.order_by('-created_at')
        
        # Paginate results
        paginator = Paginator(products, limit)
        page_obj = paginator.get_page(page)
        
        # Serialize products with variants
        products_data = []
        for product in page_obj:
            product_gender = get_product_gender(product)
            
            # Get all variants for this product
            variants_data = []
            for variant in product.variants.filter(is_active=True):
                variant_data = {
                    'id': variant.id,
                    'sku': variant.sku,
                    'price_toman': float(variant.price_toman),
                    'stock_quantity': variant.stock_quantity,
                    'is_active': variant.is_active,
                    'attributes': variant.attributes,  # JSONField
                    'created_at': variant.created_at.isoformat()
                }
                variants_data.append(variant_data)
            
            product_data = {
                'id': product.id,
                'name': product.name,
                'description': product.description,
                'category_id': product.category.id,
                'category_name': product.category.name,
                'gender': product_gender,
                'image_url': get_product_image_url(product),
                'attributes': get_product_attributes(product),
                'created_at': product.created_at.isoformat(),
                'supplier': product.supplier.name if product.supplier else None,
                'variants': variants_data,
                'variants_count': len(variants_data),
                'price_range': get_product_price_range(product),
                'total_stock': sum(v['stock_quantity'] for v in variants_data)
            }
            products_data.append(product_data)
        
        return Response({
            'success': True,
            'products': products_data,
            'pagination': {
                'page': page,
                'total_pages': paginator.num_pages,
                'total_items': paginator.count,
                'has_next': page_obj.has_next(),
                'has_previous': page_obj.has_previous()
            },
            'filters': {
                'category': category_name,
                'gender': gender,
                'search': search_query
            }
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=500)


@api_view(['GET'])
def api_product_variants(request, product_id):
    """
    Get all variants for a specific product
    URL: /api/products/{product_id}/variants/
    """
    try:
        if ProductVariant is None:
            return Response({
                'success': False,
                'error': 'ProductVariant model not available'
            }, status=500)
        
        product = Product.objects.get(id=product_id, is_active=True)
        variants = product.variants.filter(is_active=True)
        
        variants_data = []
        for variant in variants:
            variant_data = {
                'id': variant.id,
                'sku': variant.sku,
                'price_toman': float(variant.price_toman),
                'stock_quantity': variant.stock_quantity,
                'is_active': variant.is_active,
                'attributes': variant.attributes,
                'created_at': variant.created_at.isoformat()
            }
            variants_data.append(variant_data)
        
        return Response({
            'success': True,
            'product': {
                'id': product.id,
                'name': product.name,
                'description': product.description,
                'category_name': product.category.name
            },
            'variants': variants_data,
            'variants_count': len(variants_data)
        })
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'error': 'Product not found'
        }, status=404)
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=500)


@api_view(['GET'])
def api_variants_by_attributes(request):
    """
    Get variants filtered by attributes
    URL: /api/variants/
    Parameters:
        - product_id: Filter by specific product
        - attr_color: Filter by color attribute
        - attr_size: Filter by size attribute
        - page: Page number for pagination
        - limit: Items per page (default: 20)
    """
    try:
        if ProductVariant is None:
            return Response({
                'success': False,
                'error': 'ProductVariant model not available'
            }, status=500)
        
        page = int(request.GET.get('page', 1))
        limit = int(request.GET.get('limit', 20))
        product_id = request.GET.get('product_id')
        
        # Start with active variants
        variants = ProductVariant.objects.filter(is_active=True)
        
        # Filter by product
        if product_id:
            variants = variants.filter(product_id=product_id)
        
        # Filter by attributes (dynamic filtering)
        for key, value in request.GET.items():
            if key.startswith('attr_'):
                attr_name = key[5:]  # Remove 'attr_' prefix
                variants = variants.filter(attributes__contains={attr_name: value})
        
        # Order by SKU
        variants = variants.order_by('sku')
        
        # Paginate results
        paginator = Paginator(variants, limit)
        page_obj = paginator.get_page(page)
        
        # Serialize variants
        variants_data = []
        for variant in page_obj:
            variant_data = {
                'id': variant.id,
                'sku': variant.sku,
                'price_toman': float(variant.price_toman),
                'stock_quantity': variant.stock_quantity,
                'is_active': variant.is_active,
                'attributes': variant.attributes,
                'created_at': variant.created_at.isoformat(),
                'product': {
                    'id': variant.product.id,
                    'name': variant.product.name,
                    'category_name': variant.product.category.name
                }
            }
            variants_data.append(variant_data)
        
        return Response({
            'success': True,
            'variants': variants_data,
            'pagination': {
                'page': page,
                'total_pages': paginator.num_pages,
                'total_items': paginator.count,
                'has_next': page_obj.has_next(),
                'has_previous': page_obj.has_previous()
            }
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'error': str(e)
        }, status=500)


def get_product_price_range(product):
    """Get price range for a product with variants"""
    try:
        if ProductVariant is None:
            return None
        
        variants = product.variants.filter(is_active=True)
        if not variants.exists():
            return None
        
        prices = [float(v.price_toman) for v in variants if v.price_toman]
        if not prices:
            return None
        
        min_price = min(prices)
        max_price = max(prices)
        
        if min_price == max_price:
            return f"{min_price:,.0f} تومان"
        else:
            return f"{min_price:,.0f} - {max_price:,.0f} تومان"
    except:
        return None


# -----------------------------
# Session-based Basket Endpoints
# -----------------------------

BASKET_SESSION_KEY = 'basket_v1'


def _get_session_basket(request):
    """Return mutable basket dict from session; ensure structure exists.

    Structure:
    {
      'items': { str(product_id): quantity_int, ... },
      'currency': 'toman',
      'updated_at': iso_string,
    }
    """
    basket = request.session.get(BASKET_SESSION_KEY)
    if not basket or not isinstance(basket, dict):
        basket = {'items': {}, 'currency': 'toman', 'updated_at': timezone.now().isoformat()}
        request.session[BASKET_SESSION_KEY] = basket
    # normalize
    basket.setdefault('items', {})
    basket['currency'] = 'toman'
    return basket


def _save_session_basket(request, basket):
    basket['updated_at'] = timezone.now().isoformat()
    request.session[BASKET_SESSION_KEY] = basket
    request.session.modified = True


def _serialize_basket(basket):
    """Compute totals from Product.price_toman and serialize basket."""
    items = []
    merchandise_subtotal = 0.0

    product_ids = [int(pid) for pid in basket.get('items', {}).keys()]
    products_by_id = {}
    if product_ids and Product is not None:
        for p in Product.objects.filter(id__in=product_ids, is_active=True):
            products_by_id[p.id] = p

    for pid_str, qty in basket.get('items', {}).items():
        try:
            pid = int(pid_str)
        except Exception:
            continue
        quantity = max(0, int(qty))
        if quantity == 0:
            continue
        product = products_by_id.get(pid)
        if not product:
            continue
        unit_price = float(product.price_toman or 0)
        line_subtotal = unit_price * quantity
        merchandise_subtotal += line_subtotal
        items.append({
            'product': {
                'id': product.id,
                'name': product.name,
                'price_toman': unit_price,
                'image_url': get_product_image_url(product),
            },
            'quantity': quantity,
            'item_subtotal': line_subtotal,
        })

    discount_total = 0.0
    shipping_total = 0.0
    tax_total = 0.0
    grand_total = merchandise_subtotal - discount_total + shipping_total + tax_total

    return {
        'currency': 'toman',
        'items': items,
        'summary': {
            'merchandise_subtotal': merchandise_subtotal,
            'discount_total': discount_total,
            'shipping_total': shipping_total,
            'tax_total': tax_total,
            'grand_total': grand_total,
            'item_count': sum(i['quantity'] for i in items),
        }
    }


# -----------------------------
# Orders API
# -----------------------------

def serialize_order(order):
    items = []
    subtotal = 0.0
    for it in order.items.select_related('product').all():
        line = float(it.price) * it.quantity
        subtotal += line
        items.append({
            'id': it.id,
            'product': {
                'id': it.product.id,
                'name': it.product.name,
                'image_url': get_product_image_url(it.product),
            },
            'price_toman': float(it.price),
            'quantity': it.quantity,
            'subtotal': line,
        })
    return {
        'id': order.id,
        'customer': {
            'first_name': order.first_name,
            'last_name': order.last_name,
            'email': order.email,
            'address': order.address,
            'postal_code': order.postal_code,
            'city': order.city,
        },
        'created': order.created.isoformat(),
        'updated': order.updated.isoformat(),
        'paid': order.paid,
        'totals': {
            'grand_total': subtotal,
            'item_count': sum(i['quantity'] for i in items),
        },
        'items': items,
    }


@api_view(['GET'])
def api_orders_list(request):
    """List orders with search, filters, sorting, pagination."""
    if Order is None:
        return Response({'success': False, 'error': 'Order model not available'}, status=500)

    q = request.GET.get('q', '').strip()
    status_paid = request.GET.get('paid')  # 'true' | 'false' | None
    sort = request.GET.get('sort', '-created')  # '-created', 'created', '-total', 'total'
    page = int(request.GET.get('page', 1))
    limit = int(request.GET.get('limit', 20))

    orders = Order.objects.all()
    if q:
        orders = orders.filter(
            Q(first_name__icontains=q) | Q(last_name__icontains=q) | Q(email__icontains=q) | Q(id__icontains=q)
        )
    if status_paid in ['true', 'false']:
        orders = orders.filter(paid=(status_paid == 'true'))

    # Sorting
    if sort in ['created', '-created', 'updated', '-updated']:
        orders = orders.order_by(sort)
    elif sort in ['total', '-total']:
        # Annotate totals via Python after fetch; simple approach due to model simplicity
        orders = list(orders)
        orders.sort(key=lambda o: float(sum(i.price * i.quantity for i in o.items.all())), reverse=sort == '-total')
    else:
        orders = orders.order_by('-created')

    # Pagination
    paginator = Paginator(orders, limit)
    page_obj = paginator.get_page(page)

    data = [serialize_order(o) for o in page_obj]
    return Response({
        'success': True,
        'orders': data,
        'pagination': {
            'page': page,
            'total_pages': paginator.num_pages,
            'total_items': paginator.count,
            'has_next': page_obj.has_next(),
            'has_previous': page_obj.has_previous(),
        }
    })


@api_view(['GET'])
def api_orders_detail(request, order_id):
    if Order is None:
        return Response({'success': False, 'error': 'Order model not available'}, status=500)
    try:
        order = Order.objects.get(id=order_id)
    except Order.DoesNotExist:
        return Response({'success': False, 'error': 'Order not found'}, status=404)
    return Response({'success': True, 'order': serialize_order(order)})


@api_view(['POST'])
def api_orders_update_paid(request, order_id):
    if Order is None:
        return Response({'success': False, 'error': 'Order model not available'}, status=500)
    try:
        order = Order.objects.get(id=order_id)
    except Order.DoesNotExist:
        return Response({'success': False, 'error': 'Order not found'}, status=404)
    paid = request.data.get('paid')
    if paid is None:
        return Response({'success': False, 'error': 'paid is required'}, status=400)
    order.paid = bool(paid) if isinstance(paid, bool) else str(paid).lower() == 'true'
    order.save(update_fields=['paid', 'updated'])
    return Response({'success': True, 'order': serialize_order(order)})


@api_view(['GET'])
def api_orders_export_csv(request):
    if Order is None:
        return Response({'success': False, 'error': 'Order model not available'}, status=500)
    import csv
    from io import StringIO
    sio = StringIO()
    writer = csv.writer(sio)
    writer.writerow(['id','first_name','last_name','email','created','paid','item_count','grand_total'])
    for o in Order.objects.all().order_by('-created'):
        total = sum(i.price * i.quantity for i in o.items.all())
        writer.writerow([o.id, o.first_name, o.last_name, o.email, o.created.isoformat(), o.paid, o.items.count(), total])
    return Response({'success': True, 'content_type': 'text/csv', 'filename': 'orders.csv', 'data': sio.getvalue()})