from rest_framework.routers import DefaultRouter
from django.urls import path

from .views import CategoryViewSet, DiaryEntryViewSet, MoodViewSet, TagViewSet, TodayPromptView

app_name = 'diary_api'

router = DefaultRouter()
router.register('entries', DiaryEntryViewSet, basename='entry')
router.register('categories', CategoryViewSet, basename='category')
router.register('tags', TagViewSet, basename='tag')
router.register('moods', MoodViewSet, basename='mood')

urlpatterns = [
    path('prompts/today/', TodayPromptView.as_view(), name='today-prompt'),
] + router.urls
