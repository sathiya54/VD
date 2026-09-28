from django.conf import settings
from django.db import models

User = settings.AUTH_USER_MODEL


def memory_upload_path(instance, filename):
    return f'memories/{instance.owner_id}/{filename}'


class Memory(models.Model):
    TYPE_CHOICES = [
        ('photo', 'Photo'),
        ('document', 'Document'),
        ('screenshot', 'Screenshot'),
        ('certificate', 'Certificate'),
        ('project_file', 'Project file'),
    ]

    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='memories')
    title = models.CharField(max_length=200, blank=True)
    file = models.FileField(upload_to=memory_upload_path)
    memory_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='photo')
    taken_at = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title or self.file.name
