from rest_framework.authtoken.models import Token
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from .models import CustomUser
from .serializers import UserSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny  # Correct import statement
from rest_framework.permissions import IsAuthenticated  # Import IsAuthenticated
from django.db import models
from django.db.models import Q
from django.core.exceptions import ValidationError
from rest_framework.decorators import api_view, permission_classes


class SignUpView(APIView):
    permission_classes = [AllowAny]  # Add this line

    def post(self, request):
        required_fields = ['username', 'email', 'password', 'KTUID', 'semester', 'degree', 'targeted_cgpa']
        if not all(field in request.data for field in required_fields):
            response_data = {'error': 'Missing required fields'}
            print("Response data:", response_data)  # Log the response
            return Response(response_data, status=status.HTTP_400_BAD_REQUEST)

        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()  # Save user once
            refresh = RefreshToken.for_user(user)

            response_data = {  # Return tokens in response
                'user': serializer.data,
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }
            print("Response data:", response_data)  # Log the response
            return Response(response_data, status=status.HTTP_201_CREATED)

        response_data = serializer.errors
        print("Response errors:", response_data)  # Log the errors
        return Response(response_data, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    def post(self, request):
        print("\n===== NEW LOGIN REQUEST =====")
        print("Request data:", request.data)
        print("Request headers:", request.headers)
        
        email = request.data.get('email')
        password = request.data.get('password')
        print(f"Attempting login for email: {email}")

        user = authenticate(request, email=email, password=password)
        
        if user is not None:
            print(f"\nUSER FOUND - Details:")
            print(f"Email: {user.email}")
            print(f"Username: {user.username}")
            print(f"is_faculty: {user.is_faculty}")
            print(f"is_active: {user.is_active}")
            print(f"Last login: {user.last_login}")
            
            refresh = RefreshToken.for_user(user)
            response_data = {
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'is_faculty': user.is_faculty,
                'is_superuser': user.is_superuser,  # Add this line
                'user_id': user.id,
                'email': user.email,
            }
            print("\nRESPONSE DATA BEING SENT:")
            print(response_data)
            
            return Response(response_data, status=status.HTTP_200_OK)
        else:
            print("\nAUTHENTICATION FAILED")
            return Response({'error': 'Invalid credentials'}, 
                          status=status.HTTP_401_UNAUTHORIZED)

class FacultySignUpView(APIView):
    permission_classes = [AllowAny]  # Allow anyone to access this endpoint

    def post(self, request):
        print("Faculty signup request received:", request.data)  # Log request data

        required_fields = ['username', 'email', 'password', 'college_code']
        missing_fields = [field for field in required_fields if field not in request.data]
        if missing_fields:
            response_data = {'error': f'Missing required fields: {", ".join(missing_fields)}'}
            print("Faculty signup response data:", response_data)  # Log response data
            return Response(response_data, status=status.HTTP_400_BAD_REQUEST)

        # Validate email uniqueness
        if CustomUser.objects.filter(email=request.data['email']).exists():
            response_data = {'error': 'Email is already in use'}
            print("Faculty signup response data:", response_data)  # Log response data
            return Response(response_data, status=status.HTTP_400_BAD_REQUEST)

        # Validate college code
        college_code = request.data.get('college_code')
        if not college_code or len(college_code) != 3:  # Updated validation for 3-character codes
            response_data = {'error': 'Invalid college code'}
            print("Faculty signup response data:", response_data)  # Log response data
            return Response(response_data, status=status.HTTP_400_BAD_REQUEST)

        # Create the faculty user
        try:
            user = CustomUser.objects.create_faculty(
                email=request.data['email'],
                password=request.data['password'],
                username=request.data['username'],
                college_code=college_code
            )
            refresh = RefreshToken.for_user(user)
            response_data = {
                'user': {
                    'username': user.username,
                    'email': user.email,
                    'college_code': user.college_code
                },
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }
            print("Faculty signup response data:", response_data)  # Log response data
            return Response(response_data, status=status.HTTP_201_CREATED)
        except Exception as e:
            response_data = {'error': str(e)}
            print("Faculty signup response data:", response_data)  # Log response data
            return Response(response_data, status=status.HTTP_400_BAD_REQUEST)

class IsFacultyView(APIView):
    permission_classes = [IsAuthenticated]  # Ensure the user is authenticated

    def get(self, request):
        user = request.user  # Get the authenticated user
        print(f"Fetching is_faculty status for user: {user.email}")  # Log user details

        response_data = {
            'user_id': user.id,
            'email': user.email,
            'is_faculty': user.is_faculty,  # Return the is_faculty status
        }
        print("Response data:", response_data)  # Log the response
        return Response(response_data, status=status.HTTP_200_OK)


class IsAdminView(APIView):
    permission_classes = [IsAuthenticated]  # Ensure the user is authenticated

    def get(self, request):
        user = request.user  # Get the authenticated user
        print(f"Fetching is_faculty status for user: {user.email}")  # Log user details

        response_data = {
            'user_id': user.id,
            'email': user.email,
            'is_superuser': user.is_superuser,  # Return the is_faculty status
        }
        print("Response data:", response_data)  # Log the response
        return Response(response_data, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def increment_semester(request):
    if not request.user.is_superuser:
        return Response({'error': 'Permission denied'}, status=403)
    
    try:
        # Increment semester for students who are not faculty and have a semester < 8
        updated = CustomUser.objects.filter(
            is_faculty=False, # Re
            semester__lt='8',
            has_seen_increment_notification=True  # Assuming semester is stored as a CharField
        ).update(
            semester=models.Case(
                models.When(semester='1', then=models.Value('2')),
                models.When(semester='2', then=models.Value('3')),
                models.When(semester='3', then=models.Value('4')),
                models.When(semester='4', then=models.Value('5')),
                models.When(semester='5', then=models.Value('6')),
                models.When(semester='6', then=models.Value('7')),
                models.When(semester='7', then=models.Value('8')),
                default=models.F('semester')
            ),
            has_seen_increment_notification=False  # Reset notification status
        )
        
        return Response({
            'success': True,
            'updated_count': updated
        })
    except Exception as e:
        return Response({'error': str(e)}, status=400)

from .models import Notification
from rest_framework import serializers

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'header', 'content', 'created_at', 'is_read']

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_notifications(request):
    try:
        notifications = Notification.objects.filter(
            recipient=request.user
        ).order_by('-created_at')
        serializer = NotificationSerializer(notifications, many=True)
        return Response(serializer.data)
    except Exception as e:
        return Response({'error': str(e)}, status=400)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_as_read(request, notification_id):
    try:
        notification = Notification.objects.get(
            id=notification_id,
            recipient=request.user
        )
        notification.is_read = True
        notification.save()
        return Response({'success': True})
    except Notification.DoesNotExist:
        return Response({'error': 'Notification not found'}, status=404)
    except Exception as e:
        return Response({'error': str(e)}, status=400)

# Update your existing send_notification view


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_notification(request):
    if not request.user.is_superuser:
        return Response({'error': 'Permission denied'}, status=403)
    
    header = request.data.get('header')
    content = request.data.get('content')
    
    if not header or not content:
        return Response({'error': 'Both header and content are required'}, status=400)
    
    try:
        # Get all active users (students and faculty)
        users = CustomUser.objects.filter(is_active=True)
        
        # Create notifications for each user
        notifications = [
            Notification(
                recipient=user,
                sender=request.user,
                header=header,
                content=content
            )
            for user in users
        ]
        Notification.objects.bulk_create(notifications)
        
        return Response({
            'success': True,
            'message': f'Notification sent to {users.count()} users'
        })
    except Exception as e:
        return Response({'error': str(e)}, status=400)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_increment_notification(request):
    user = request.user
    if user.is_faculty or user.is_superuser:
        return Response({'show_notification': False})  # No notification for faculty or superusers

    if not user.has_seen_increment_notification:
        return Response({
            'show_notification': True,
            'message': f"Your semester has been incremented to {user.semester}. Please confirm your readiness."
        })
    return Response({'show_notification': False})

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def confirm_increment_notification(request):
    user = request.user
    user.has_seen_increment_notification = True
    user.save()
    return Response({'success': True, 'message': 'Notification confirmed'})



@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deny_increment_notification(request):
    user = request.user
    if user.is_faculty or user.is_superuser:
        return Response({'error': 'Only students can deny the increment'}, status=403)

    try:
        # Decrement the semester if it's greater than 1
        if user.semester and int(user.semester) > 1:
            user.semester = str(int(user.semester) - 1)
            user.has_seen_increment_notification = True  # Mark notification as seen
            user.save()
            return Response({'success': True, 'message': 'Semester increment denied and reverted'})
        else:
            return Response({'error': 'Cannot decrement semester below 1'}, status=400)
    except Exception as e:
        return Response({'error': str(e)}, status=400)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_minor_status(request):
    try:
        user = request.user
        is_minor = request.data.get('is_minor', False)  # Get the value from the request
        user.is_minor = is_minor
        user.save()
        return Response({'success': True, 'message': 'Minor status updated successfully'})
    except Exception as e:
        return Response({'error': str(e)}, status=400)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_honor_status(request):
    try:
        user = request.user
        is_honors = request.data.get('is_honors', False)  # Get the value from the request
        user.is_honors = is_honors
        user.save()
        return Response({'success': True, 'message': 'Honor status updated successfully'})
    except Exception as e:
        return Response({'error': str(e)}, status=400)

