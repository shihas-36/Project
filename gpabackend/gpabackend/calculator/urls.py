from django.urls import path
from . import views

urlpatterns = [
    path('get_subjects/', views.get_subjects, name='get_subjects'),
    path('get_user_data/', views.get_user_data, name='get_user_data'),
    path('calculate_gpa/', views.calculate_gpa, name='calculate_gpa'),
    path('calculate_grade/', views.calculate_grade, name='garde_subject'),
    path('calculate_minor/', views.calculate_minor, name='calculate_minor'),  # Add the new endpoint
    path('get_minor_subjects/', views.get_minor_subjects, name='get_minor_subjects'),  # Add the new endpoint
    path('check_minor_status/', views.check_minor_status, name='minor_stat'),  # Add the new endpoint
]