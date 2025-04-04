from django.urls import path

from .views import SignUpView, LoginView, FacultySignUpView, IsFacultyView, IsAdminView ,increment_semester,send_notification,mark_as_read,get_notifications  # Import the new view
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
    # Add the new endpoint for faculty to get students by college code
     # Add the new endpoint 
]