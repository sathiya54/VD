from django.contrib import admin

from .models import Event


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ['title', 'owner', 'start_datetime', 'all_day', 'location']
    list_filter = ['all_day']
