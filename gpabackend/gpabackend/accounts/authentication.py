from rest_framework_simplejwt.authentication import JWTAuthentication

class InactiveUserJWTAuthentication(JWTAuthentication):
    def get_user(self, validated_token):
        user = super().get_user(validated_token)
        # Bypass the is_active check
        return user