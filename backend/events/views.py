from datetime import date

from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from diary.models import DiaryEntry
from goals.models import Goal
from reminders.models import Reminder
from tasks.models import Task

from .models import Event
from .serializers import EventSerializer


class EventViewSet(viewsets.ModelViewSet):
    serializer_class = EventSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Event.objects.filter(owner=self.request.user)


class CalendarView(APIView):
    """Aggregates everything that belongs on the calendar for a given
    month: diary entries, tasks, goals (by target date), reminders and
    events. Kept as a single read-only endpoint rather than five separate
    round trips, since the mobile calendar screen needs all of it at once."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        today = date.today()
        year = int(request.query_params.get('year', today.year))
        month = int(request.query_params.get('month', today.month))
        user = request.user

        entries = DiaryEntry.objects.filter(
            owner=user, deleted_at__isnull=True, date__year=year, date__month=month,
        ).values('id', 'title', 'date')

        tasks = Task.objects.filter(
            owner=user, due_date__year=year, due_date__month=month,
        ).values('id', 'title', 'due_date', 'is_done')

        goals = Goal.objects.filter(
            owner=user, target_date__year=year, target_date__month=month,
        ).values('id', 'title', 'target_date', 'status')

        reminders = Reminder.objects.filter(
            owner=user, is_active=True, remind_at__year=year, remind_at__month=month,
        ).values('id', 'title', 'remind_at', 'repeat')

        events = Event.objects.filter(
            owner=user, start_datetime__year=year, start_datetime__month=month,
        ).values('id', 'title', 'start_datetime', 'end_datetime', 'all_day')

        return Response({
            'year': year,
            'month': month,
            'entries': list(entries),
            'tasks': list(tasks),
            'goals': list(goals),
            'reminders': list(reminders),
            'events': list(events),
        })
