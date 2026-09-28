from django.contrib import admin

from .models import Task


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'owner', 'priority', 'is_done', 'due_date', 'goal']
    list_filter = ['priority', 'is_done']
    search_fields = ['title', 'owner__username']
