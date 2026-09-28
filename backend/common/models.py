import uuid

from django.conf import settings
from django.db import models


class SyncModel(models.Model):
    """Abstract base for records that will eventually sync with mobile
    offline storage. Every synchronized object carries created_at, updated_at,
    deleted_at and version so the future sync engine can detect conflicts
    without ever blindly overwriting newer data."""

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    version = models.PositiveIntegerField(default=1)

    class Meta:
        abstract = True

    @property
    def is_deleted(self):
        return self.deleted_at is not None

    def soft_delete(self):
        from django.utils import timezone
        self.deleted_at = timezone.now()
        self.version += 1
        self.save(update_fields=['deleted_at', 'version'])

    def restore(self):
        self.deleted_at = None
        self.version += 1
        self.save(update_fields=['deleted_at', 'version'])


class AuditLog(models.Model):
    """Security-relevant events (login, logout, failed login, password
    change, account deletion). Never store diary content or secrets here."""

    ACTION_CHOICES = [
        ('login', 'Login'),
        ('login_failed', 'Login failed'),
        ('logout', 'Logout'),
        ('register', 'Register'),
        ('password_change', 'Password changed'),
        ('account_deleted', 'Account deleted'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='audit_logs')
    action = models.CharField(max_length=32, choices=ACTION_CHOICES)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.action} - {self.user} @ {self.created_at:%Y-%m-%d %H:%M}'
