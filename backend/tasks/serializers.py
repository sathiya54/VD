from rest_framework import serializers

from diary.models import DiaryEntry
from goals.models import Goal

from .models import Task


class TaskSerializer(serializers.ModelSerializer):
    goal = serializers.PrimaryKeyRelatedField(queryset=Goal.objects.none(), required=False, allow_null=True)
    diary_entry = serializers.PrimaryKeyRelatedField(queryset=DiaryEntry.objects.none(), required=False, allow_null=True)

    class Meta:
        model = Task
        fields = ['id', 'title', 'description', 'due_date', 'priority', 'is_done', 'goal', 'diary_entry', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        request = self.context.get('request')
        if request is not None:
            self.fields['goal'].queryset = Goal.objects.filter(owner=request.user)
            self.fields['diary_entry'].queryset = DiaryEntry.objects.filter(owner=request.user)

    def create(self, validated_data):
        validated_data['owner'] = self.context['request'].user
        return super().create(validated_data)
