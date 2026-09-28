from django.contrib import admin

from .models import Achievement, AchievementDefinition


@admin.register(AchievementDefinition)
class AchievementDefinitionAdmin(admin.ModelAdmin):
    list_display = ['code', 'title', 'icon']


@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    list_display = ['owner', 'definition', 'achieved_at']
    list_filter = ['definition']
