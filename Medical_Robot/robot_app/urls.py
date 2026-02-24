from django.urls import path, include


urlpatterns = [
    # ...
    path('', include('robot_app.urls')), # السطر ده بيربط مشروعك بملف الـ api                            
]