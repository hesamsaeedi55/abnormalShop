import os
from django.core.management.utils import get_random_secret_key

SECRET_KEY = os.environ.get("SECRET_KEY", get_random_secret_key())
