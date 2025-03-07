from django.contrib import admin
from .models import CustomUser, Subject, Semester, Grade

admin.site.register(CustomUser)
admin.site.register(Subject)
admin.site.register(Semester)
admin.site.register(Grade)
