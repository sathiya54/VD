from django.urls import include, path

urlpatterns = [
    path('auth/', include('accounts.urls')),
    path('', include('diary.urls')),
    path('', include('goals.urls')),
    path('', include('tasks.urls')),
    path('', include('reminders.urls')),
    path('', include('events.urls')),
    path('', include('memories.urls')),
    path('', include('notifications.urls')),
    path('', include('achievements.urls')),
    path('', include('search.urls')),
    path('', include('analytics.urls')),
    path('', include('ai_assistant.urls')),
]
