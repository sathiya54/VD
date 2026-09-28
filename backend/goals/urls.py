from rest_framework.routers import DefaultRouter

from .views import GoalViewSet, MilestoneViewSet

app_name = 'goals_api'

router = DefaultRouter()
router.register('goals', GoalViewSet, basename='goal')
router.register('milestones', MilestoneViewSet, basename='milestone')

urlpatterns = router.urls
