from rest_framework.generics import ListAPIView
from rest_framework.permissions import IsAuthenticated

from diary.models import DiaryEntry
from diary.serializers import DiaryEntrySerializer
from diary.views import apply_common_filters


class SearchView(ListAPIView):
    serializer_class = DiaryEntrySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        base = DiaryEntry.objects.filter(owner=self.request.user, deleted_at__isnull=True)
        return apply_common_filters(base, self.request.query_params).select_related('mood', 'category').prefetch_related('tags')
