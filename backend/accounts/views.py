from django.contrib.auth import login as django_login
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_decode, urlsafe_base64_encode
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.token_blacklist.models import OutstandingToken

from common.models import AuditLog
from .models import Profile, User
from .serializers import (
    AccountDeleteSerializer,
    PasswordChangeSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    ProfileUpdateSerializer,
    RegisterSerializer,
    UserSerializer,
)


def _tokens_for(user):
    refresh = RefreshToken.for_user(user)
    return {'access': str(refresh.access_token), 'refresh': str(refresh)}


def _client_ip(request):
    forwarded = request.META.get('HTTP_X_FORWARDED_FOR')
    return forwarded.split(',')[0] if forwarded else request.META.get('REMOTE_ADDR')


class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer
    throttle_scope = 'auth'

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        AuditLog.objects.create(user=user, action='register', ip_address=_client_ip(request))
        tokens = _tokens_for(user)
        return Response(
            {**tokens, 'user': UserSerializer(user).data},
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_scope = 'auth'

    def post(self, request):
        username = request.data.get('username', '')
        password = request.data.get('password', '')
        try:
            user = User.objects.get(username__iexact=username)
        except User.DoesNotExist:
            user = None

        if user is None or not user.check_password(password) or not user.is_active:
            AuditLog.objects.create(action='login_failed', ip_address=_client_ip(request))
            return Response(
                {'detail': 'Invalid credentials.', 'error_code': 'invalid_credentials'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        django_login(request, user)
        AuditLog.objects.create(user=user, action='login', ip_address=_client_ip(request))
        tokens = _tokens_for(user)
        return Response({**tokens, 'user': UserSerializer(user).data})


class LogoutView(APIView):
    def post(self, request):
        refresh = request.data.get('refresh')
        if not refresh:
            return Response({'detail': 'refresh is required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            token = RefreshToken(refresh)
            token.blacklist()
        except TokenError:
            pass
        AuditLog.objects.create(user=request.user, action='logout', ip_address=_client_ip(request))
        return Response(status=status.HTTP_205_RESET_CONTENT)


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = ProfileUpdateSerializer

    def get_object(self):
        profile, _ = Profile.objects.get_or_create(user=self.request.user)
        return profile

    def retrieve(self, request, *args, **kwargs):
        return Response(UserSerializer(request.user).data)

    def update(self, request, *args, **kwargs):
        super().update(request, *args, **kwargs)
        request.user.refresh_from_db()
        return Response(UserSerializer(request.user).data)


class PasswordChangeView(generics.GenericAPIView):
    serializer_class = PasswordChangeSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        AuditLog.objects.create(user=request.user, action='password_change', ip_address=_client_ip(request))
        return Response({'detail': 'Password changed successfully.'})


class PasswordResetRequestView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = PasswordResetRequestSerializer
    throttle_scope = 'auth'

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = User.objects.filter(email__iexact=serializer.validated_data['email']).first()
        if user:
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            token = default_token_generator.make_token(user)
            # In production this would link to the web app's reset page; for
            # now it's emailed via the console backend in development.
            send_mail(
                subject='Reset your Virtual Diary password',
                message=f'Use this code to reset your password:\nuid={uid}\ntoken={token}',
                from_email=None,
                recipient_list=[user.email],
                fail_silently=True,
            )
        # Always return 200 — never reveal whether an email is registered.
        return Response({'detail': 'If that email is registered, a reset link has been sent.'})


class PasswordResetConfirmView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = PasswordResetConfirmSerializer
    throttle_scope = 'auth'

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            uid = force_str(urlsafe_base64_decode(serializer.validated_data['uid']))
            user = User.objects.get(pk=uid)
        except (User.DoesNotExist, ValueError, TypeError, OverflowError):
            user = None

        if not user or not default_token_generator.check_token(user, serializer.validated_data['token']):
            return Response(
                {'detail': 'Invalid or expired reset link.', 'error_code': 'invalid_reset_token'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(serializer.validated_data['new_password'])
        user.save()
        AuditLog.objects.create(user=user, action='password_change', ip_address=_client_ip(request))
        return Response({'detail': 'Password has been reset. You can now log in.'})


class AccountDeleteView(generics.GenericAPIView):
    serializer_class = AccountDeleteSerializer

    def delete(self, request):
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        AuditLog.objects.create(user=None, action='account_deleted', ip_address=_client_ip(request))
        # Outstanding tokens reference the user via FK; delete them explicitly
        # before the user row disappears (avoids orphaned blacklist rows).
        OutstandingToken.objects.filter(user=request.user).delete()
        request.user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
