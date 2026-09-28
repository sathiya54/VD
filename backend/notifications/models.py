from django.conf import settings
from django.db import models

User = settings.AUTH_USER_MODEL


class Notification(models.Model):
    TYPE_CHOICES = [
        ('reminder', 'Reminder'),
        ('task_deadline', 'Task deadline'),
        ('goal_deadline', 'Goal deadline'),
        ('writing_streak', 'Writing streak'),
        ('achievement', 'Achievement'),
        ('memory_reminder', 'Memory reminder'),
        ('system', 'System'),
    ]

    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='system')
    title = models.CharField(max_length=200)
    message = models.CharField(max_length=500, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title
