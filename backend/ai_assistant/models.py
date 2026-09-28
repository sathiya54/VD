from django.conf import settings
from django.db import models

User = settings.AUTH_USER_MODEL


class AIRequest(models.Model):
    REQUEST_TYPES = [
        ('title', 'Generate title'),
        ('summary', 'Summarize'),
        ('tags', 'Generate tags'),
        ('improve', 'Improve writing'),
    ]
    STATUS_CHOICES = [('success', 'Success'), ('error', 'Error'), ('timeout', 'Timeout')]

    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ai_requests')
    request_type = models.CharField(max_length=20, choices=REQUEST_TYPES)
    input_length = models.PositiveIntegerField(default=0)
    output_length = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.request_type} ({self.status}) - {self.owner}'
