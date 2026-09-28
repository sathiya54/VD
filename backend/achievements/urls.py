from rest_framework.routers import DefaultRouter

from .views import AchievementViewSet

app_name = 'achievements_api'

router = DefaultRouter()
router.register('achievements', AchievementViewSet, basename='achievement')

urlpatterns = router.urls
