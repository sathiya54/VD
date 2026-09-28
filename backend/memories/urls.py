from rest_framework.routers import DefaultRouter

from .views import MemoryViewSet

app_name = 'memories_api'

router = DefaultRouter()
router.register('memories', MemoryViewSet, basename='memory')

urlpatterns = router.urls
