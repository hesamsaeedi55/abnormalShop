import os
from django.core.management.utils import get_random_secret_key

# Use environment variable if set, otherwise generate a random key
SECRET_KEY = os.environ.get("d3d411f23ba7be8d9700fb20072bac6c", get_random_secret_key())
