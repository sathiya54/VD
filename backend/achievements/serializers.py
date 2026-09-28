from rest_framework import serializers

from .models import Achievement


class AchievementSerializer(serializers.ModelSerializer):
    title = serializers.CharField(source='definition.title')
    description = serializers.CharField(source='definition.description')
    icon = serializers.CharField(source='definition.icon')

    class Meta:
        model = Achievement
        fields = ['id', 'title', 'description', 'icon', 'achieved_at']
