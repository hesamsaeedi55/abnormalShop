from django.contrib.auth import authenticate
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json
from django.shortcuts import render
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from google.oauth2 import id_token
from google.auth.transport import requests
from django.conf import settings

User = get_user_model()

@csrf_exempt
@require_http_methods(["POST"])
def token_view(request):
    try:
        data = json.loads(request.body)
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return JsonResponse({
                'error': 'Email and password are required'
            }, status=400)
        
        user = authenticate(username=email, password=password)
        
        if user is not None and user.is_active:
            # For now, we'll return dummy tokens
            # In production, you should use proper JWT token generation
            return JsonResponse({
                'access': 'dummy_access_token',
                'refresh': 'dummy_refresh_token'
            })
        else:
            return JsonResponse({
                'error': 'Invalid credentials'
            }, status=401)
            
    except json.JSONDecodeError:
        return JsonResponse({
            'error': 'Invalid JSON data'
        }, status=400)
    except Exception as e:
        return JsonResponse({
            'error': str(e)
        }, status=500)

def home(request):
    return render(request, 'home.html')

# def google_auth_view(request):
#     ... 