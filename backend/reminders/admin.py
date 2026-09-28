from django.contrib import admin

from .models import Reminder


@admin.register(Reminder)
class ReminderAdmin(admin.ModelAdmin):
    list_display = ['title', 'owner', 'remind_at', 'repeat', 'is_active']
    list_filter = ['repeat', 'is_active']
