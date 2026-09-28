from collections import Counter

from django.utils import timezone
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from diary.models import DiaryEntry
from diary.serializers import DiaryEntrySerializer
from goals.models import Goal
from tasks.models import Task


class AnalyticsSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        entries = DiaryEntry.objects.filter(owner=user, deleted_at__isnull=True)

        mood_counts = Counter(entries.exclude(mood__isnull=True).values_list('mood__name', flat=True))
        category_counts = Counter(entries.exclude(category__isnull=True).values_list('category__name', flat=True))

        profile = user.profile
        return Response({
            'total_entries': entries.count(),
            'current_streak': profile.current_streak,
            'longest_streak': profile.longest_streak,
            'mood_distribution': dict(mood_counts),
            'category_distribution': dict(category_counts),
            'goals_completed': Goal.objects.filter(owner=user, status='completed').count(),
            'tasks_completed': Task.objects.filter(owner=user, is_done=True).count(),
        })


class OnThisDayView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        today = timezone.now().date()
        entries = DiaryEntry.objects.filter(
            owner=request.user,
            deleted_at__isnull=True,
            date__day=today.day,
            date__month=today.month,
        ).exclude(date__year=today.year).order_by('-date')

        results = [
            {'year': entry.date.year, 'entry': DiaryEntrySerializer(entry, context={'request': request}).data}
            for entry in entries
        ]
        return Response(results)
