from rest_framework import serializers
from .models import Semester, Grade

class GradeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Grade
        fields = ['subject', 'grade']

class SemesterSerializer(serializers.ModelSerializer):
    grades = GradeSerializer(many=True, read_only=True)

    class Meta:
        model = Semester
        fields = ['semester_number', 'gpa', 'cgpa', 'grades']
