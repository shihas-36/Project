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