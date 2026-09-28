from django.urls import path

from . import views

app_name = 'ai_api'

urlpatterns = [
    path('ai/title/', views.TitleView.as_view(), name='title'),
    path('ai/summary/', views.SummaryView.as_view(), name='summary'),
    path('ai/tags/', views.TagsView.as_view(), name='tags'),
    path('ai/improve/', views.ImproveView.as_view(), name='improve'),
]
