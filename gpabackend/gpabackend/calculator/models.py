from django.db import models
from accounts.models import CustomUser  # Import the CustomUser model from accounts

class Semester(models.Model):
    """
    Model to store semester information for each user.
    """
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='semesters')
    semester = models.CharField(max_length=20, default='semester_1')  # Use CharField with default value
    gpa = models.FloatField(null=True, blank=True)  # GPA for this semester
    cgpa = models.FloatField(null=True, blank=True)  # Cumulative GPA up to this semester

    class Meta:
        unique_together = ('user', 'semester')  # Ensure unique semesters per user

    def __str__(self):
        return f"{self.user.username} - Semester {self.semester}"

class Subject(models.Model):
    """
    Model to store subjects and their credits for each semester.
    """
    semester = models.ForeignKey(Semester, on_delete=models.CASCADE, related_name='subjects')
    name = models.CharField(max_length=100)  # e.g., "Physics", "Maths"
    credits = models.IntegerField()  # Credits for the subject

    class Meta:
        unique_together = ('semester', 'name')  # Ensure unique subjects per semester

    def __str__(self):
        return f"{self.name} ({self.credits} credits)"

class Grade(models.Model):
    """
    Model to store grades for each subject in a semester.
    """
    subject = models.OneToOneField(Subject, on_delete=models.CASCADE, related_name='grade')
    grade = models.CharField(max_length=2, choices=[
        ('S', 'S'), ('A', 'A'), ('B', 'B'),
        ('C', 'C'), ('D', 'D'), ('F', 'F')
    ])  # Grade for the subject

    def __str__(self):
        return f"{self.subject.name} - {self.grade}"
