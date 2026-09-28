from django.urls import path

from .views import AnalyticsSummaryView, OnThisDayView

app_name = 'analytics_api'

urlpatterns = [
    path('analytics/summary/', AnalyticsSummaryView.as_view(), name='summary'),
    path('analytics/on-this-day/', OnThisDayView.as_view(), name='on-this-day'),
]
