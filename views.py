from django.http import JsonResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import get_user_model
from django.contrib.admin.views.decorators import staff_member_required
from rest_framework_simplejwt.tokens import RefreshToken
import json
from google.oauth2 import id_token
from google.auth.transport import requests
from django.conf import settings
from rest_framework_simplejwt.exceptions import TokenError

User = get_user_model()

@csrf_exempt
def refresh_token_view(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            refresh_token = data.get('refresh')
            
            if not refresh_token:
                return JsonResponse({'error': 'Refresh token is required'}, status=400)
            
            # Create a RefreshToken instance from the token string
            refresh = RefreshToken(refresh_token)
            
            # Generate new access token and refresh token
            new_access_token = str(refresh.access_token)
            new_refresh_token = str(refresh)
            
            return JsonResponse({
                'access': new_access_token,
                'refresh': new_refresh_token
            })
            
        except TokenError:
            return JsonResponse({'error': 'Invalid refresh token'}, status=401)
        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
            
    return JsonResponse({'error': 'Method not allowed'}, status=405) 


@staff_member_required
def admin_baskets_view(request):
    """Serve the React baskets admin page as a static HTML response (staff-only)."""
    try:
        with open('/Users/hesamoddinsaeedi/Desktop/best/backup copy 53/admin-baskets.html', 'r', encoding='utf-8') as f:
            content = f.read()
        return HttpResponse(content)
    except Exception as e:
        return HttpResponse(f"Error loading admin-baskets.html: {e}", status=500)