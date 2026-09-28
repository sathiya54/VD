from django.contrib import admin

from .models import Memory


@admin.register(Memory)
class MemoryAdmin(admin.ModelAdmin):
    list_display = ['title', 'owner', 'memory_type', 'taken_at', 'created_at']
    list_filter = ['memory_type']
