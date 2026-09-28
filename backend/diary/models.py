from django.conf import settings
from django.db import models

from common.models import SyncModel

User = settings.AUTH_USER_MODEL


class Category(models.Model):
    """owner=None means a system default category, shared by all users."""

    name = models.CharField(max_length=60)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True, related_name='categories')

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['name', 'owner'], name='unique_category_per_owner'),
        ]
        verbose_name_plural = 'categories'
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def is_default(self):
        return self.owner_id is None


class Tag(models.Model):
    name = models.CharField(max_length=60)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='tags')

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['name', 'owner'], name='unique_tag_per_owner'),
        ]
        ordering = ['name']

    def __str__(self):
        return self.name


class Mood(models.Model):
    """owner=None means a system default mood, shared by all users."""

    name = models.CharField(max_length=40)
    emoji = models.CharField(max_length=8)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True, related_name='moods')
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order', 'name']
        constraints = [
            models.UniqueConstraint(fields=['name', 'owner'], name='unique_mood_per_owner'),
        ]

    def __str__(self):
        return f'{self.emoji} {self.name}'


def cover_image_upload_path(instance, filename):
    return f'diary/{instance.owner_id}/covers/{filename}'


class DiaryEntry(SyncModel):
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='diary_entries')
    title = models.CharField(max_length=200, blank=True)
    content = models.TextField(blank=True)
    date = models.DateField()
    time = models.TimeField(null=True, blank=True)
    mood = models.ForeignKey(Mood, on_delete=models.SET_NULL, null=True, blank=True, related_name='entries')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='entries')
    tags = models.ManyToManyField(Tag, blank=True, related_name='entries')
    cover_image = models.ImageField(upload_to=cover_image_upload_path, null=True, blank=True)
    location_label = models.CharField(max_length=120, blank=True, help_text='Coarse location only, e.g. city name.')
    is_favorite = models.BooleanField(default=False)
    is_private = models.BooleanField(default=True)

    class Meta:
        ordering = ['-date', '-time', '-created_at']
        indexes = [
            models.Index(fields=['owner', 'date']),
            models.Index(fields=['owner', 'is_favorite']),
            models.Index(fields=['owner', 'deleted_at']),
        ]
        verbose_name_plural = 'diary entries'

    def __str__(self):
        return self.title or f'Entry #{self.pk}'


def attachment_upload_path(instance, filename):
    return f'diary/{instance.entry.owner_id}/attachments/{filename}'


class Attachment(models.Model):
    entry = models.ForeignKey(DiaryEntry, on_delete=models.CASCADE, related_name='attachments')
    file = models.FileField(upload_to=attachment_upload_path)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.file.name


class JournalPrompt(models.Model):
    text = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.text
