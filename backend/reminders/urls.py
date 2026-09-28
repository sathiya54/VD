from rest_framework.routers import DefaultRouter

from .views import ReminderViewSet

app_name = 'reminders_api'

router = DefaultRouter()
router.register('reminders', ReminderViewSet, basename='reminder')

urlpatterns = router.urls
