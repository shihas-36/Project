from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import Semester, Subject, Grade
from rest_framework.permissions import AllowAny
from accounts.models import CustomUser
from .courses import CREDITS  # Import the credits from courses.py

# Grade values mapping
GRADE_VALUES = {
    'S': 10, 'A': 9, 'A+': 8.5, 'B+': 8, 'B': 7.5, 'C+': 7, 'C': 6.5, 'D+': 6, 'P': 5.5, 'F': 0
}

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_subjects(request):
    """
    Returns the list of subjects and credits for each semester based on the user's degree.
    """
    user = request.user
    degree = user.degree
    if degree not in CREDITS:
        return Response({'error': 'Invalid degree'}, status=status.HTTP_400_BAD_REQUEST)
    return Response(CREDITS[degree])

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_data(request):
    try:
        user = request.user
        semesters = Semester.objects.filter(user=user).prefetch_related('subjects__grade')

        semester_data = []
        for semester in semesters:
            semester_info = {
                'semester': semester.semester,
                'gpa': semester.gpa,
                'subjects': []
            }

            for subject in semester.subjects.all():
                try:
                    grade = subject.grade.grade
                except Grade.DoesNotExist:
                    grade = None

                semester_info['subjects'].append({
                    'name': subject.name,
                    'credits': subject.credits,
                    'grade': grade
                })

            semester_data.append(semester_info)

        all_gpas = [s.gpa for s in semesters if s.gpa is not None]
        cgpa = sum(all_gpas) / len(all_gpas) if len(all_gpas) > 0 else 0.0

        return Response({
            'semesters': semester_data,
            'cgpa': round(cgpa, 2)
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def calculate_gpa(request):
    try:
        print("Request received")  # Log request received
        print("Request body:", request.body)  # Log raw request body
        data = request.data
        print("Received payload:", data)  # Print the received payload

        user = request.user
        semester = data.get('semester')
        grades = data.get('grades', {})

        # Validate semester
        if not semester or not isinstance(semester, str):
            return Response(
                {'error': 'Invalid semester'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if the semester is within the user's current semester
        user_current_semester = user.semester  # Use the semester field from CustomUser model
        try:
            semester_number = int(semester.split('_')[-1])
            user_current_semester_number = int(user_current_semester.split('_')[-1])
        except (IndexError, ValueError):
            return Response(
                {'error': 'Invalid semester format'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if semester_number > user_current_semester_number:
            return Response(
                {'error': 'You can only calculate GPA up to your current semester.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create or update semester
        semester_obj, created = Semester.objects.get_or_create(
            user=user,
            semester=semester
        )

        total_credits = 0
        total_points = 0

        for subject_name, grade in grades.items():
            # Use the original subject name directly
            credits = CREDITS[user.degree].get(semester, {}).get(subject_name.strip())  # .strip() to handle accidental spaces
            
            if credits is None:
                return Response(
                    {'error': f'Credits not found for subject "{subject_name}" in {semester}'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Get or create the subject with original name
            subject, _ = Subject.objects.get_or_create(
                semester=semester_obj,
                name=subject_name.strip(),  # Store original name
                defaults={'credits': credits}
            )

            # Ensure the subject credits are correctly set
            subject.credits = credits
            subject.save()

            Grade.objects.update_or_create(
                subject=subject,
                defaults={'grade': grade}
            )

            # Calculate GPA
            if grade in GRADE_VALUES:
                total_credits += subject.credits
                total_points += GRADE_VALUES[grade] * subject.credits

        if total_credits == 0:
            return Response(
                {'error': 'No valid grades provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Save GPA for the semester
        gpa = total_points / total_credits
        semester_obj.gpa = gpa
        semester_obj.save()

        all_semesters = Semester.objects.filter(user=user)
        try:
            cgpa = sum(s.gpa for s in all_semesters if s.gpa is not None) / len(all_semesters)
        except TypeError as e:
            print("TypeError in CGPA calculation:", e)
            return Response(
                {'error': f'TypeError in CGPA calculation: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        print("GPA and CGPA calculated successfully")  # Log successful calculation
        return Response({
            'semester_gpa': round(gpa, 2),
            'cgpa': round(cgpa, 2)
        }, status=status.HTTP_200_OK)

    except Exception as e:
        print("An error occurred:", e)  # Print the error
        return Response(
            {'error': f'An unexpected error occurred: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )