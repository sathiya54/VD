from django.conf import settings
from django.db import models

User = settings.AUTH_USER_MODEL


class AchievementDefinition(models.Model):
    """A catalog of unlockable achievements. `code` is checked against by
    the achievement-evaluation logic (see services.py)."""

    code = models.CharField(max_length=50, unique=True)
    title = models.CharField(max_length=120)
    description = models.CharField(max_length=255)
    icon = models.CharField(max_length=50, default='star')

    def __str__(self):
        return self.title


class Achievement(models.Model):
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='achievements')
    definition = models.ForeignKey(AchievementDefinition, on_delete=models.CASCADE, related_name='unlocks')
    achieved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=['owner', 'definition'], name='unique_achievement_per_owner')]
        ordering = ['-achieved_at']

    def __str__(self):
        return f'{self.owner} - {self.definition.title}'
