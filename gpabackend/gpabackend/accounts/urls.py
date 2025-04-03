from django.urls import path
from .views import SignUpView, LoginView, FacultySignUpView, IsFacultyView

urlpatterns = [
    path('api/signup/', SignUpView.as_view(), name='signup'),
    path('api/login/', LoginView.as_view(), name='login'),
    path('api/faculty/', FacultySignUpView.as_view(), name='faculty'),
    path('api/is_faculty/', IsFacultyView.as_view(), name='is_faculty'),
]