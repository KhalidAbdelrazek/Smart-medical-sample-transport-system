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

def debug_stats():
    now = timezone.now()
    today = timezone.localdate()
    print(f"Server Time (UTC): {now}")
    print(f"Local Date (Cairo): {today}")
    
    requests = TransportRequest.objects.all()
    print(f"Total Transport Requests in DB: {requests.count()}")
    
    for req in requests[:10]:
        print(f"ID: {req.id} | Doctor: {req.requested_by} | Created: {req.created_at} | Status: {req.status}")
        # Check date comparison
        req_local_date = timezone.localtime(req.created_at).date()
        print(f"  Local Date: {req_local_date} | Matches Today? {req_local_date == today}")

if __name__ == "__main__":
    debug_stats()
