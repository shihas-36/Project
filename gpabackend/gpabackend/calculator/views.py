from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from .models import Semester, Subject, Grade
from accounts.models import CustomUser
from .courses import CREDITS
from .minor import MINOR, HONOR  # Import the credits from minor.py
from django.db.models import Max, Min, Count, Q  # Add this import
cgpa=0
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
    print("User degree:", degree)  # Log the user's degree
    if degree not in CREDITS:
        response_data = {'error': 'Invalid degree'}
        print("Response data:", response_data)  # Log the response
        return Response(response_data, status=status.HTTP_400_BAD_REQUEST)
    
    response_data = CREDITS[degree]
    print("Response data:", response_data)  # Log the response
    return Response(response_data)


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
                'minor_gpa': semester.minor_gpa,  # Include minor GPA
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

        response_data = {
            'semesters': semester_data,
            'cgpa': round(cgpa, 2)
        }

        print("Response data:", response_data)  # Log the response
        return Response(response_data, status=status.HTTP_200_OK)

    except Exception as e:
        error_response = {'error': str(e)}
        print("Response data:", error_response)  # Log the error response
        return Response(error_response, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def calculate_gpa(request):
    try:
        data = request.data
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
        user_current_semester = user.semester
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

        for subject_name, grade in grades.items():
            credits = CREDITS[user.degree].get(semester, {}).get(subject_name.strip())
            if credits is None:
                return Response(
                    {'error': f'Credits not found for subject "{subject_name}" in {semester}'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            subject, _ = Subject.objects.get_or_create(
                semester=semester_obj,
                name=subject_name.strip(),
                defaults={'credits': credits}
            )

            subject.credits = credits
            subject.save()

            Grade.objects.update_or_create(
                subject=subject,
                defaults={'grade': grade}
            )

            if grade in GRADE_VALUES:
                semester_obj.total_credits += subject.credits
                semester_obj.total_points += GRADE_VALUES[grade] * subject.credits
                if grade != 'F':
                    semester_obj.earn_credits += subject.credits

        if semester_obj.total_credits == 0:
            return Response(
                {'error': 'No valid grades provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Save GPA for the semester
        gpa = semester_obj.total_points / semester_obj.total_credits
        semester_obj.gpa = gpa
        semester_obj.save()

        # Calculate and update CGPA for the user
        all_semesters = Semester.objects.filter(user=user)
        try:
            cgpa = sum(s.gpa for s in all_semesters if s.gpa is not None) / len(all_semesters)
        except TypeError as e:
            print("TypeError in CGPA calculation:", e)
            return Response(
                {'error': f'TypeError in CGPA calculation: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.cgpa = cgpa  # Update the user's CGPA
        user.save()
        print("hii ",user.cgpa) # Save the user instance to the database

        print("CGPA:", user.cgpa)  # Log CGPA
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

@api_view(['POST'])
@permission_classes([AllowAny])
def calculate_grade(request):
    try:
        print("Request body:", request.data)  # Log request body
        marks = request.data.get('marks')
        if marks is None:
            response_data = {'error': 'Marks are required'}
            print("Response body:", response_data)  # Log response body
            return Response(response_data, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            marks = float(marks)
        except ValueError:
            response_data = {'error': 'Invalid marks format'}
            print("Response body:", response_data)  # Log response body
            return Response(response_data, status=status.HTTP_400_BAD_REQUEST)
        
        if marks < 0 or marks > 150:
            response_data = {'error': 'Marks should be between 0 and 100'}
            print("Response body:", response_data)  # Log response body
            return Response(response_data, status=status.HTTP_400_BAD_REQUEST)
        
        grade = None
        if marks >= 135:
            grade = 'S'
        elif marks >= 127.5:
            grade = 'A+'
        elif marks >= 120:
            grade = 'A'
        elif marks >= 112.5:
            grade = 'B+'
        elif marks >= 105:
            grade = 'B'
        elif marks >= 97.5:
            grade = 'C+'
        elif marks >= 90:
            grade = 'C'
        elif marks >= 82.5:
            grade = 'D+'
        elif marks >= 75:
            grade = 'P'
        else:
            grade = 'F'
        
        response_data = {'grade': grade}
        print("Response body:", response_data)  # Log response body
        return Response(response_data, status=status.HTTP_200_OK)
    except Exception as e:
        response_data = {'error': str(e)}
        print("Response body:", response_data)  # Log response body
        return Response(response_data, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def calculate_minor(request):
    try:
        print("Request received for minor calculation")  # Log request received
        print("Request body:", request.body)  # Log raw request body
        data = request.data
        print("Received payload:", data)  # Print the received payload

        user = request.user
        semester = data.get('semester')
        minor_grades = data.get('minor_grades', {})
        Bucket = data.get('Bucket', 'Bucket 1')  # Define and get the selected bucket
        Type = data.get('Type', 'Minor')  # Define and get the selected type (Minor or Honor)
        print("THIS ISSSSS", minor_grades)  # Ensure this line is executed

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

        # Get the existing semester object
        semester_obj = Semester.objects.get(user=user, semester=semester)

        # Initialize total_credits and total_points if not already set
        if semester_obj.total_credits is None:
            semester_obj.total_credits = 0
        if semester_obj.total_points is None:
            semester_obj.total_points = 0
        print("semester_obj.total_credits:", semester_obj.total_credits)  # Log total_credits
        print("semester_obj.total_points:", semester_obj.total_points)  # Log total_points

        # Select the correct dictionary based on the type
        selected_dict = MINOR if Type == 'Minor' else HONOR

        for subject_name, grade in minor_grades.items():
            # Use the original subject name directly
            credits = selected_dict[user.degree].get(Bucket, {}).get(semester, {}).get(subject_name.strip())  # Correct reference to selected_dict
           
            if credits is None:
                print(f'Credits not found for subject "{subject_name}" in {semester}')  # Log missing credits
                return Response(
                    {'error': f'Credits not found for subject "{subject_name}" in {semester}'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Save or update the subject and grade
            subject, _ = Subject.objects.get_or_create(
                semester=semester_obj,
                name=subject_name.strip(),
                defaults={'credits': credits}
            )
            subject.credits = credits
            subject.save()

            Grade.objects.update_or_create(
                subject=subject,
                defaults={'grade': grade}
            )

            # Calculate additional SGPA
            if grade in GRADE_VALUES:
                semester_obj.total_credits += credits
                semester_obj.total_points += GRADE_VALUES[grade] * credits

        if semester_obj.total_credits == 0:
            return Response(
                {'error': 'No valid grades provided'},
                status=status.HTTP_400_BAD_REQUEST
            )
        print("semester_obj.total_credits:", semester_obj.total_credits)  # Log total_credits
        print("semester_obj.total_points:", semester_obj.total_points)  # Log total_points
        # Save updated SGPA for the semester
        acsgpa = semester_obj.total_points / semester_obj.total_credits
        semester_obj.minor_gpa = acsgpa  # Save the minor GPA in the database
        semester_obj.save()  # Persist the changes to the database
        print("SGPA:", semester_obj.gpa, "Minor GPA:", semester_obj.minor_gpa)  # Log successful SGPA calculation

        all_semesters = Semester.objects.filter(user=user)
        try:
            minor_cgpa = sum(s.gpa for s in all_semesters if s.gpa is not None) / len(all_semesters)
        except TypeError as e:
            print("TypeError in CGPA calculation:", e)
            return Response(
                {'error': f'TypeError in CGPA calculation: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Include updated grades in the response
        updated_grades = {
            subject.name: subject.grade.grade if subject.grade else None
            for subject in semester_obj.subjects.all()
        }

        print("SGPA and CGPA calculated successfully")  # Log successful calculation
        return Response({
            'semester_sgpa': round(acsgpa, 2),  # Return the updated SGPA
            'cgpa': round(minor_cgpa, 2),
            'updated_grades': updated_grades  # Include updated grades in the response
        }, status=status.HTTP_200_OK)

    except Exception as e:
        print("An error occurred:", e)  # Print the error
        return Response(
            {'error': f'An unexpected error occurred: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_minor_status(request):
    """
    Check if the user is a minor or honor student.
    """
    try:
        user = request.user
        is_minor_student = user.is_minor  # Assuming you have this field in your CustomUser model
        is_honor_student = user.is_honors  # Assuming you have this field in your CustomUser model
        return Response({
            'is_minor_student': is_minor_student,
            'is_honor_student': is_honor_student
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_minor_subjects(request):
    """
    Returns the list of minor and honor subjects and credits for each semester based on the user's degree.
    """
    try:
        user = request.user
        degree = user.degree
        print("User degree:", degree)  # Log the user's degree

        minor_subjects = MINOR.get(degree, {})
        honor_subjects = HONOR.get(degree, {})

        if not minor_subjects and not honor_subjects:
            print("Invalid degree or no minor/honor subjects available")  # Log the error condition
            return Response({'error': 'Invalid degree or no minor/honor subjects available'}, status=status.HTTP_400_BAD_REQUEST)

        response_data = {
            'Minor': minor_subjects,
            'Honor': honor_subjects
        }
        print("Response data:", response_data)  # Print the response data
        return Response(response_data)
    except Exception as e:
        print("Error in get_minor_subjects:", str(e))  # Log the error
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Ensure this line is present
def summury(request):
    user = request.user
    print("User:", user)
    print("qwe",user.cgpa)  # Log the user
    best_semester = user.semesters.aggregate(Max('gpa'))['gpa__max']  # Correct field name
    worst_semester = user.semesters.aggregate(Min('gpa'))['gpa__min']  # Correct field name
    topper_count = Subject.objects.filter(semester__user=user, grade__grade='S').count()  # Correct access to subjects
    supply_count = Subject.objects.filter(semester__user=user, grade__grade='F').count()  # Correct access to subjects

    # Calculate total credits and earned credits
    semesters = Semester.objects.filter(user=user)
    total_credits = [semester.total_credits for semester in semesters]
    earned_credits = [semester.earn_credits for semester in semesters]

    # Calculate yearback required credits
    current_semester = int(user.semester.split('_')[-1])
    print("Current semester:", current_semester)  # Log current semester
    yearback_required = 0

    if current_semester <= 4:
        first_two_semesters_total = sum(total_credits[:2])
        print("First two semesters total credits:", first_two_semesters_total)  # Log first two semesters total credits
        first_two_semesters_earned = sum(earned_credits[:2])
        print("First two semesters earned credits:", first_two_semesters_earned)  # Log first two semesters earned credits
        difference = first_two_semesters_total - first_two_semesters_earned
        print("Difference:", difference)
        yearback_required = 0 if difference > 17 else 17 - difference   
        
    elif current_semester <= 6:
        first_four_semesters_total = sum(total_credits[:4])
        first_four_semesters_earned = sum(earned_credits[:4])
        difference = first_four_semesters_total - first_four_semesters_earned
        yearback_required = 0 if difference > 41 else 41 - difference

    # Calculate SGPA required for upcoming semesters to achieve targeted CGPA
    targeted_cgpa = user.targeted_cgpa
    print("Targeted CGPA:", targeted_cgpa)  # Log targeted CGPA
    sgpa_required = None
    total_semesters = 8  # Assuming 8 semesters in total
    if targeted_cgpa and current_semester < total_semesters:
        remaining_semesters = total_semesters - current_semester
        print("Remaining semesters:", remaining_semesters)  # Log remaining semesters
        cgpsum = user.cgpa  # Use the user's CGPA field, default to 0.0 if null
        print("CGPA sum:", cgpsum)
        req=targeted_cgpa * total_semesters
        print("Required CGPA:", req)
        sgpa_required = (
            ( req - cgpsum) 
            / remaining_semesters
        )
        sgpa_required = round(sgpa_required, 2)
        print("SGPA required:", sgpa_required)  # Log SGPA required

    return Response({
        'best_semester': best_semester,
        'worst_semester': worst_semester,
        'topper_count': topper_count,
        'supply_count': supply_count,
        'current_semester': user.semester,
        'total_credits': total_credits,
        'earned_credits': earned_credits,
        'yearback_required': yearback_required,
        'sgpa_required': sgpa_required
    }, status=status.HTTP_200_OK)