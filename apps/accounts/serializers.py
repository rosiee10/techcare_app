from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """User serializer for profile data"""
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'employee_id', 'role', 'department', 
                  'phone', 'first_name', 'last_name', 'is_active_staff', 'date_joined_hospital']
        read_only_fields = ['id']


class RegisterSerializer(serializers.ModelSerializer):
    """User registration serializer with role validation"""
    password = serializers.CharField(
        write_only=True, 
        required=True, 
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password2 = serializers.CharField(
        write_only=True, 
        required=True, 
        style={'input_type': 'password'}
    )

    class Meta:
        model = User
        fields = ['username', 'password', 'password2', 'email', 'employee_id', 
                  'role', 'department', 'phone', 'first_name', 'last_name']

    def validate(self, attrs):
        """Validate password match"""
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        """Create user with validated data"""
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Custom JWT token serializer with user role data"""
    
    def validate(self, attrs):
        data = super().validate(attrs)
        
        # Add user data to token response
        user = self.user
        data['user'] = {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'role': user.role,
            'department': user.department,
            'employee_id': user.employee_id,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'is_active_staff': user.is_active_staff,
        }
        return data
