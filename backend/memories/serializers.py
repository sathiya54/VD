import os

from django.conf import settings
from rest_framework import serializers

from .models import Memory


class MemorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Memory
        fields = ['id', 'title', 'file', 'memory_type', 'taken_at', 'created_at']
        read_only_fields = ['id', 'created_at']

    def validate_file(self, value):
        if value.size > settings.MAX_UPLOAD_SIZE_BYTES:
            raise serializers.ValidationError('File is too large (max 10 MB).')
        ext = os.path.splitext(value.name)[1].lower()
        allowed = settings.ALLOWED_IMAGE_EXTENSIONS + settings.ALLOWED_DOCUMENT_EXTENSIONS
        if ext not in allowed:
            raise serializers.ValidationError(f'Unsupported file type "{ext}".')
        return value

    def create(self, validated_data):
        validated_data['owner'] = self.context['request'].user
        return super().create(validated_data)
