from django.contrib.auth.tokens import default_token_generator
from django.urls import reverse
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from rest_framework import status
from rest_framework.test import APITestCase

from .models import User


class AuthFlowTests(APITestCase):
    def test_register_creates_user_and_returns_tokens(self):
        url = reverse('accounts_api:register')
        response = self.client.post(url, {
            'username': 'alice', 'email': 'alice@example.com',
            'password': 'StrongPass123', 'password2': 'StrongPass123',
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertTrue(User.objects.filter(username='alice').exists())
        # A profile should be auto-created via the post_save signal.
        self.assertTrue(User.objects.get(username='alice').profile)

    def test_register_rejects_mismatched_passwords(self):
        url = reverse('accounts_api:register')
        response = self.client.post(url, {
            'username': 'bob', 'email': 'bob@example.com',
            'password': 'StrongPass123', 'password2': 'Different123',
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_with_correct_credentials(self):
        User.objects.create_user(username='carol', email='carol@example.com', password='StrongPass123')
        response = self.client.post(reverse('accounts_api:login'), {'username': 'carol', 'password': 'StrongPass123'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)

    def test_login_with_wrong_password_fails(self):
        User.objects.create_user(username='carol', email='carol@example.com', password='StrongPass123')
        response = self.client.post(reverse('accounts_api:login'), {'username': 'carol', 'password': 'wrong'})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_profile_requires_authentication(self):
        response = self.client.get(reverse('accounts_api:profile'))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_user_can_fetch_and_update_profile(self):
        user = User.objects.create_user(username='dave', email='dave@example.com', password='StrongPass123')
        self.client.force_authenticate(user=user)
        response = self.client.get(reverse('accounts_api:profile'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'dave')

        response = self.client.patch(reverse('accounts_api:profile'), {'bio': 'Hello world'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        user.profile.refresh_from_db()
        self.assertEqual(user.profile.bio, 'Hello world')

    def test_password_change_requires_correct_old_password(self):
        user = User.objects.create_user(username='erin', email='erin@example.com', password='StrongPass123')
        self.client.force_authenticate(user=user)
        response = self.client.post(reverse('accounts_api:password-change'), {
            'old_password': 'wrong', 'new_password': 'NewStrongPass123',
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_account_delete_requires_correct_password(self):
        user = User.objects.create_user(username='frank', email='frank@example.com', password='StrongPass123')
        self.client.force_authenticate(user=user)
        response = self.client.delete(reverse('accounts_api:account-delete'), {'password': 'wrong'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        response = self.client.delete(reverse('accounts_api:account-delete'), {'password': 'StrongPass123'})
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(User.objects.filter(username='frank').exists())

    def test_password_reset_flow(self):
        user = User.objects.create_user(username='grace', email='grace@example.com', password='OldPass123')

        response = self.client.post(reverse('accounts_api:password-reset'), {'email': 'grace@example.com'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        uid = urlsafe_base64_encode(force_bytes(user.pk))
        token = default_token_generator.make_token(user)
        response = self.client.post(reverse('accounts_api:password-reset-confirm'), {
            'uid': uid, 'token': token, 'new_password': 'BrandNewPass123',
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        response = self.client.post(reverse('accounts_api:login'), {'username': 'grace', 'password': 'BrandNewPass123'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_password_reset_request_does_not_leak_unknown_email(self):
        response = self.client.post(reverse('accounts_api:password-reset'), {'email': 'nobody@example.com'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_password_reset_confirm_rejects_bad_token(self):
        user = User.objects.create_user(username='henry', email='henry@example.com', password='OldPass123')
        uid = urlsafe_base64_encode(force_bytes(user.pk))
        response = self.client.post(reverse('accounts_api:password-reset-confirm'), {
            'uid': uid, 'token': 'not-a-real-token', 'new_password': 'BrandNewPass123',
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
