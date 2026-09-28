from django.db.models import Q
from django.utils import timezone
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Category, DiaryEntry, JournalPrompt, Mood, Tag
from .serializers import (
    CategorySerializer,
    DiaryEntrySerializer,
    JournalPromptSerializer,
    MoodSerializer,
    TagSerializer,
)


def apply_common_filters(queryset, params):
    category = params.get('category')
    mood = params.get('mood')
    tag = params.get('tag')
    favorite = params.get('favorite')
    search = params.get('search') or params.get('q')
    date_from = params.get('date_from')
    date_to = params.get('date_to')

    if category:
        queryset = queryset.filter(category_id=category)
    if mood:
        queryset = queryset.filter(mood_id=mood)
    if tag:
        queryset = queryset.filter(tags__id=tag)
    if favorite is not None:
        queryset = queryset.filter(is_favorite=str(favorite).lower() in ('1', 'true', 'yes'))
    if date_from:
        queryset = queryset.filter(date__gte=date_from)
    if date_to:
        queryset = queryset.filter(date__lte=date_to)
    if search:
        queryset = queryset.filter(
            Q(title__icontains=search)
            | Q(content__icontains=search)
            | Q(tags__name__icontains=search)
            | Q(category__name__icontains=search)
            | Q(mood__name__icontains=search)
        )
    return queryset.distinct()


class DiaryEntryViewSet(viewsets.ModelViewSet):
    serializer_class = DiaryEntrySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        base = DiaryEntry.objects.filter(owner=self.request.user)
        base = base.filter(deleted_at__isnull=True) if self.action != 'trash' else base.filter(deleted_at__isnull=False)
        return apply_common_filters(base, self.request.query_params).select_related('mood', 'category').prefetch_related('tags', 'attachments')

    def perform_destroy(self, instance):
        instance.soft_delete()
        update_streak(self.request.user)

    def perform_create(self, serializer):
        entry = serializer.save()
        update_streak(self.request.user, entry.date)

    @action(detail=True, methods=['post'])
    def favorite(self, request, pk=None):
        entry = self.get_object()
        entry.is_favorite = not entry.is_favorite
        entry.version += 1
        entry.save(update_fields=['is_favorite', 'version'])
        return Response(self.get_serializer(entry).data)

    @action(detail=True, methods=['post'])
    def restore(self, request, pk=None):
        entry = DiaryEntry.objects.filter(owner=request.user, pk=pk, deleted_at__isnull=False).first()
        if not entry:
            return Response({'detail': 'Not found in trash.'}, status=status.HTTP_404_NOT_FOUND)
        entry.restore()
        return Response(self.get_serializer(entry).data)

    @action(detail=True, methods=['delete'], url_path='permanent')
    def permanent_delete(self, request, pk=None):
        entry = DiaryEntry.objects.filter(owner=request.user, pk=pk).first()
        if not entry:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        entry.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def trash(self, request):
        page = self.paginate_queryset(self.get_queryset())
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)


class CategoryViewSet(mixins.ListModelMixin, mixins.CreateModelMixin, mixins.DestroyModelMixin, viewsets.GenericViewSet):
    serializer_class = CategorySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Category.objects.filter(Q(owner=self.request.user) | Q(owner__isnull=True))

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    def perform_destroy(self, instance):
        if instance.owner_id != self.request.user.id:
            raise PermissionDenied('Cannot delete a default category.')
        instance.delete()


class TagViewSet(mixins.ListModelMixin, mixins.CreateModelMixin, mixins.DestroyModelMixin, viewsets.GenericViewSet):
    serializer_class = TagSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Tag.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class MoodViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = MoodSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Mood.objects.filter(Q(owner=self.request.user) | Q(owner__isnull=True))


class TodayPromptView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        prompts = list(JournalPrompt.objects.filter(is_active=True))
        if not prompts:
            return Response({'id': None, 'text': 'What was the best part of your day?'})
        seed = timezone.now().date().toordinal()
        prompt = prompts[seed % len(prompts)]
        return Response(JournalPromptSerializer(prompt).data)


def update_streak(user, entry_date=None):
    """Recompute the user's writing streak. Kept simple and correct rather
    than trying to incrementally patch it — diary entries are edited/deleted
    rarely enough that a full recompute is cheap."""
    profile = user.profile
    dates = set(
        DiaryEntry.objects.filter(owner=user, deleted_at__isnull=True).values_list('date', flat=True)
    )
    if not dates:
        profile.current_streak = 0
        profile.last_entry_date = None
        profile.save(update_fields=['current_streak', 'last_entry_date'])
        return

    today = timezone.now().date()
    current = 0
    cursor = today if today in dates else today - timezone.timedelta(days=1)
    while cursor in dates:
        current += 1
        cursor -= timezone.timedelta(days=1)

    longest = max(profile.longest_streak, current)
    profile.current_streak = current
    profile.longest_streak = longest
    profile.last_entry_date = max(dates)
    profile.save(update_fields=['current_streak', 'longest_streak', 'last_entry_date'])
