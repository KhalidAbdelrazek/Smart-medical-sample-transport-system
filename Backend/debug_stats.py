import os
import django
import sys
from django.utils import timezone

# Set up Django environment
sys.path.append('d:/gad/Smart-medical-sample-transport-system/Medical_Robot')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'Medical_Robot.settings')
django.setup()

from transport.models import TransportRequest
from accounts.models import User

