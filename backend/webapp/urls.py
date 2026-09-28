from django.contrib.auth import views as auth_views
from django.urls import path

from . import views

app_name = 'web'

urlpatterns = [
    path('', views.dashboard_view, name='dashboard'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('register/', views.register_view, name='register'),
    path('logout/', views.logout_view, name='logout'),
    path('password-reset/', auth_views.PasswordResetView.as_view(
        template_name='web/auth/password_reset.html',
        email_template_name='web/auth/password_reset_email.txt',
        success_url='/password-reset/done/',
    ), name='password-reset'),
    path('password-reset/done/', auth_views.PasswordResetDoneView.as_view(
        template_name='web/auth/password_reset_done.html',
    ), name='password-reset-done'),
    path('password-reset/confirm/<uidb64>/<token>/', auth_views.PasswordResetConfirmView.as_view(
        template_name='web/auth/password_reset_confirm.html',
        success_url='/password-reset/complete/',
    ), name='password-reset-confirm'),
    path('password-reset/complete/', auth_views.PasswordResetCompleteView.as_view(
        template_name='web/auth/password_reset_complete.html',
    ), name='password-reset-complete'),

    path('diary/', views.diary_list_view, name='diary-list'),
    path('diary/new/', views.diary_create_view, name='diary-create'),
    path('diary/<int:pk>/', views.diary_detail_view, name='diary-detail'),
    path('diary/<int:pk>/edit/', views.diary_edit_view, name='diary-edit'),
    path('diary/<int:pk>/delete/', views.diary_delete_view, name='diary-delete'),
    path('diary/<int:pk>/favorite/', views.diary_favorite_toggle, name='diary-favorite'),
    path('trash/', views.trash_view, name='trash'),
    path('trash/<int:pk>/restore/', views.trash_restore_view, name='trash-restore'),
    path('trash/<int:pk>/delete/', views.trash_permanent_delete_view, name='trash-delete'),

    path('goals/', views.goals_list_view, name='goals-list'),
    path('goals/new/', views.goal_create_view, name='goal-create'),

    path('tasks/', views.tasks_list_view, name='tasks-list'),
    path('tasks/<int:pk>/toggle/', views.task_toggle_view, name='task-toggle'),

    path('profile/', views.profile_view, name='profile'),

    path('privacy/', views.privacy_policy_view, name='privacy'),
    path('about/', views.about_view, name='about'),
    path('help/', views.help_view, name='help'),
]
