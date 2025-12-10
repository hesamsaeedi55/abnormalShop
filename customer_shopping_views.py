"""
Customer Shopping Interface Views
================================

Add these views to your Django project to serve the customer shopping interface.
"""

from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.utils.decorators import method_decorator
from django.views import View
import json
import os

def customer_shopping_interface(request):
    """
    Serve the customer shopping interface HTML page
    """
    # Get the path to the HTML file
    html_file_path = os.path.join(os.path.dirname(__file__), 'customer_shopping_interface.html')
    
    try:
        with open(html_file_path, 'r', encoding='utf-8') as f:
            html_content = f.read()
        return HttpResponse(html_content, content_type='text/html')
    except FileNotFoundError:
        return HttpResponse("Shopping interface not found. Please ensure customer_shopping_interface.html exists.", status=404)

# Add this URL pattern to your urls.py:
# path('shopping/', customer_shopping_interface, name='customer_shopping'),
