from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import Profile, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    list_display = ['username', 'email', 'is_active', 'is_staff', 'date_joined']
    search_fields = ['username', 'email']


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'ai_enabled', 'current_streak', 'longest_streak', 'dark_mode_pref']
    search_fields = ['user__username', 'user__email']
    list_filter = ['ai_enabled', 'dark_mode_pref']
