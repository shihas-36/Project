from rest_framework import serializers
from .models import CustomUser
from django.contrib.auth.hashers import make_password

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = [
            'id', 'username', 'email', 'password', 'KTUID', 'semester', 
            'degree', 'targeted_cgpa', 'is_faculty', 'college_code'
        ]
        extra_kwargs = {
            'password': {'write_only': True}
        }

    def create(self, validated_data):
        is_faculty = validated_data.get('is_faculty', False)
        
        # Remove fields not required for faculty
        if is_faculty:
            validated_data.pop('KTUID', None)
            validated_data.pop('semester', None)
            validated_data.pop('degree', None)
            validated_data.pop('targeted_cgpa', None)
        else:
            # Remove fields not required for students
            validated_data.pop('college_code', None)

        # Hash the password before saving
        validated_data['password'] = make_password(validated_data['password'])
        user = CustomUser.objects.create(**validated_data)
        return user