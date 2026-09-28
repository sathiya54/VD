from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Memory
from .serializers import MemorySerializer


class MemoryViewSet(viewsets.ModelViewSet):
    serializer_class = MemorySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Memory.objects.filter(owner=self.request.user)
        memory_type = self.request.query_params.get('memory_type')
        if memory_type:
            queryset = queryset.filter(memory_type=memory_type)
        return queryset
