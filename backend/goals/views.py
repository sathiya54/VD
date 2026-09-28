from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Goal, Milestone
from .serializers import GoalSerializer, MilestoneSerializer


class GoalViewSet(viewsets.ModelViewSet):
    serializer_class = GoalSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Goal.objects.filter(owner=self.request.user).prefetch_related('milestones')

    @action(detail=True, methods=['get', 'post'])
    def milestones(self, request, pk=None):
        goal = self.get_object()
        if request.method == 'POST':
            serializer = MilestoneSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            serializer.save(goal=goal)
            return Response(serializer.data, status=201)
        return Response(MilestoneSerializer(goal.milestones.all(), many=True).data)


class MilestoneViewSet(mixins.UpdateModelMixin, mixins.DestroyModelMixin, viewsets.GenericViewSet):
    serializer_class = MilestoneSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Milestone.objects.filter(goal__owner=self.request.user)
