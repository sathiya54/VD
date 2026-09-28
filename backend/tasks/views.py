from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Task
from .serializers import TaskSerializer


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Task.objects.filter(owner=self.request.user)
        is_done = self.request.query_params.get('is_done')
        if is_done is not None:
            queryset = queryset.filter(is_done=str(is_done).lower() in ('1', 'true', 'yes'))
        return queryset

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        task = self.get_object()
        task.is_done = not task.is_done
        task.save(update_fields=['is_done', 'updated_at'])
        return Response(self.get_serializer(task).data)
