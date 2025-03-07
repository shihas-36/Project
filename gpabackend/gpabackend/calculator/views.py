from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import Semester, Subject, Grade
from rest_framework.permissions import AllowAny
from accounts.models import CustomUser
# Grade values mapping
GRADE_VALUES = {
    'S': 10, 'A': 9,'A+':8.5 ,'B+': 8,'B':7.5,'C+':7,'C':6.5,'D+':6,'P':5.5,'F':0

}

# Credits for each subject (can be moved to a database model if needed)
CREDITS = {
    'semester_1': {
        'LINEAR ALGEBRA AND CALCULAS ': 4,
        'ENGINEERING PHYSICS A ': 4,
        'ENGINEERING CHEMISTRY ': 4,
        'ENGINEERING MECHANICS': 3,
        'ENGINEERING GRAPHICS ': 3,
        'BASICS OF CIVIL & MECHANICAL ENGINEERING0 ': 4,
        'BASICS OF ELECTRICAL & ELECTRONICS ENGINEERING ': 4,
        'LIFE SKILLS': 0,
        'ENGINEERING PHYSICS LAB ': 1,
        'CIVIL & MECHANICAL WORKSHOP ':1,
        'ELECTRICAL & ELECTRONICS WORKSHOP':1,
    },
    'semester_2': {
        'VECTORCALCULUS , DIFFERENTIAL EQUATIONS AND TRANSFORMS ': 4,
        'ENGINEERING PHYSICS A ': 4,
        'ENGINEERING CHEMISTRY': 4,
        'ENGINEERING MECHANICS': 3,
        'ENGINEERING GRAPHICS': 3,
        'BASICS OF CIVIL & MECHANICAL ENGINEERING ': 4,
        'BASICS OF ELECTRICAL & ELECTRONICS ENGINEERING ': 4,
        'PROFESSIONAL COMMUNICATION': 0,
        'PROGRAMMING IN C': 4,
        'ENGINEERING PHYSICS LAB': 1,
        'ENGINEERING CHEMISTRY LAB ': 1,
        'CIVIL & MECHANICAL WORKSHOP': 1,
        'ELECTRICAL & ELECTRONICS WORKSHOP': 1,
    },
    'semester_3': {
        'DISCRETE MATHEMATICAL STRUCTURES ': 4,
        'DATA STRUCTURES': 4,
        'LOGIC SYSTEM DESIGN ': 4,
        'OBJECT ORIENTED PROGRAMMING USING JAVA': 4,
        'DESIGN & ENGINEERING': 2,
        'PROFESSIONAL ETHICS ': 2,
        'SUSTAINABLE ENGINEERING ': 0,
        'DATA STRUCTURES LAB ': 2,
        'OBJECT ORIENTED PROGRAMMING LAB (IN JAVA)': 2,
    },
    'semester_4': {
        'GRAPH THEORY': 4,
        'COMPUTER ORGANISATION AND ARCHITECTURE ': 4,
        'DATABASE MANAGEMENT SYSTEMS': 4,
        'OPERATING SYSTEMS': 4,
        'DESIGN & ENGINEERING': 2,
        'PROFESSIONAL ETHICS': 2,
        'CONSTITUTION OF INDIA': 0,
        'DIGITAL LAB ': 2,
        'OPERATING SYSTEMS LAB ': 2,
    },
    'semester_5': {
        'FORMAL LANGUAGES AND AUTOMATA THEORY': 4,
        'COMPUTER NETWORKS': 4,
        'SYSTEM SOFTWARE ': 4,
        'MICROPROCESSORS AND MICROCONTROLLERS ': 4,
        'MANAGEMENT OF SOFTWARE SYSTEMS': 3,
        'DISASTER MANAGEMENT': 0,
        'SYSTEM SOFTWARE AND MICROPROCESSORS LAB ': 2,
        'DATABASE MANAGEMENT SYSTEMS LAB ': 2,
    },
    'semester_6': {
        'COMPILER DESIGN': 4,
        'COMPUTER GRAPHICS AND IMAGE PROCESSING': 4,
        'ALGORITHM ANA LYSIS AND DESIGN': 4,
        'PROGRAM ELECTIVE I ': 3,
        'INDUSTRIAL ECONOMICS & FOREIGN TRADE ': 3,
        'COMPREHENSIVE COURSE WORK ': 1,
        'NETWORKING LAB': 2,
        'MINIPROJECT ':2
    },
}

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_subjects(request):
    """
    Returns the list of subjects and credits for each semester.
    """
    return Response(CREDITS)


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
        user = request.user
        semester = request.data.get('semester')
        grades = request.data.get('grades', {})

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
            # Get or create the subject
            subject, _ = Subject.objects.get_or_create(
                semester=semester_obj,
                name=subject_name,
                defaults={'credits': CREDITS.get(semester, {}).get(subject_name, 3)}
            )

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
        cgpa = sum(s.gpa for s in all_semesters) / len(all_semesters)

        return Response({
            'semester_gpa': round(gpa, 2),
            'cgpa': round(cgpa, 2)
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': f'An unexpected error occurred: {str(e)}'},
            status=status.HTTP_400_BAD_REQUEST
        )
