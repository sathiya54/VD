from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom user model (kept close to Django's default) so the project
    never has to migrate away from django.contrib.auth.User later. Login
    still uses `username` + `password`; `email` is required and unique so
    it can be used for password resets and notifications."""

    email = models.EmailField(unique=True)

    def __str__(self):
        return self.username


def avatar_upload_path(instance, filename):
    return f'avatars/{instance.user_id}/{filename}'


class Profile(models.Model):
    DARK_MODE_CHOICES = [('light', 'Light'), ('dark', 'Dark'), ('system', 'System')]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    avatar = models.ImageField(upload_to=avatar_upload_path, null=True, blank=True)
    bio = models.CharField(max_length=280, blank=True)

    # AI settings — AI is optional and off by default; the user must opt in.
    ai_enabled = models.BooleanField(default=False)
    ai_allow_summary = models.BooleanField(default=True)
    ai_allow_improve = models.BooleanField(default=True)
    ai_allow_search = models.BooleanField(default=True)

    dark_mode_pref = models.CharField(max_length=10, choices=DARK_MODE_CHOICES, default='system')
    language = models.CharField(max_length=8, default='en')
    location_enabled = models.BooleanField(default=False)

    current_streak = models.PositiveIntegerField(default=0)
    longest_streak = models.PositiveIntegerField(default=0)
    last_entry_date = models.DateField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f'Profile<{self.user.username}>'
