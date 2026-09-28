from rest_framework import mixins, viewsets
from rest_framework.permissions import IsAuthenticated

from .serializers import AchievementSerializer
from .services import evaluate_achievements


class AchievementViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = AchievementSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        return evaluate_achievements(self.request.user)
