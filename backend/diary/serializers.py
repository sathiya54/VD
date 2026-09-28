from rest_framework import serializers

from .models import Attachment, Category, DiaryEntry, JournalPrompt, Mood, Tag


class CategorySerializer(serializers.ModelSerializer):
    is_default = serializers.BooleanField(read_only=True)

    class Meta:
        model = Category
        fields = ['id', 'name', 'is_default']


class TagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tag
        fields = ['id', 'name']


class MoodSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mood
        fields = ['id', 'name', 'emoji']


class AttachmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Attachment
        fields = ['id', 'file', 'uploaded_at']


class JournalPromptSerializer(serializers.ModelSerializer):
    class Meta:
        model = JournalPrompt
        fields = ['id', 'text']


class DiaryEntrySerializer(serializers.ModelSerializer):
    tags = serializers.PrimaryKeyRelatedField(queryset=Tag.objects.none(), many=True, required=False)
    attachments = AttachmentSerializer(many=True, read_only=True)
    mood_detail = MoodSerializer(source='mood', read_only=True)
    category_detail = CategorySerializer(source='category', read_only=True)
    tags_detail = TagSerializer(source='tags', many=True, read_only=True)

    class Meta:
        model = DiaryEntry
        fields = [
            'id', 'title', 'content', 'date', 'time', 'mood', 'mood_detail',
            'category', 'category_detail', 'tags', 'tags_detail', 'cover_image',
            'location_label', 'is_favorite', 'is_private', 'attachments',
            'created_at', 'updated_at', 'version',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'version']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        request = self.context.get('request')
        if request is not None:
            self.fields['tags'].queryset = Tag.objects.filter(owner=request.user)

    def validate_mood(self, value):
        if value is not None and value.owner_id not in (None, self._request_user_id()):
            raise serializers.ValidationError('Invalid mood.')
        return value

    def validate_category(self, value):
        if value is not None and value.owner_id not in (None, self._request_user_id()):
            raise serializers.ValidationError('Invalid category.')
        return value

    def _request_user_id(self):
        request = self.context.get('request')
        return request.user.id if request else None

    def create(self, validated_data):
        validated_data['owner'] = self.context['request'].user
        tags = validated_data.pop('tags', [])
        entry = DiaryEntry.objects.create(**validated_data)
        entry.tags.set(tags)
        return entry

    def update(self, instance, validated_data):
        tags = validated_data.pop('tags', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.version += 1
        instance.save()
        if tags is not None:
            instance.tags.set(tags)
        return instance
