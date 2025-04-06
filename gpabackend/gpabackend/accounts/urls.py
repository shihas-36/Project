from django.urls import path

from .views import * 
from .views import update_minor_status, update_honor_status
urlpatterns = [
    path('api/signup/', SignUpView.as_view(), name='signup'),
    path('api/login/', LoginView.as_view(), name='login'),
    path('api/faculty/', FacultySignUpView.as_view(), name='faculty'),
    path('api/is_faculty/', IsFacultyView.as_view(), name='is_faculty'),
    path('api/is_admin/', IsAdminView.as_view(), name='is_admin'),
    path('api/increment_semester/', increment_semester, name='increment_semester'),
    path('api/send_notification/', send_notification, name='send_notification'),
    path('api/notifications/20/read/', mark_as_read, name='mark_as_read'),
    path('api/notifications/', get_notifications, name='get_notifications'),  # Add the new endpoint
    path('check_increment_notification/', check_increment_notification, name='check_increment_notification'),
    path('confirm_increment_notification/', confirm_increment_notification, name='confirm_increment_notification'),
    path('deny_increment_notification/', deny_increment_notification, name='deny_increment_notification'),  # Add the new endpoint
    path('update_minor_status/', update_minor_status, name='update_minor_status'),
    path('update_honor_status/', update_honor_status, name='update_honor_status'),

]