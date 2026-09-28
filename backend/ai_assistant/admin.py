from django.contrib import admin

from .models import AIRequest


@admin.register(AIRequest)
class AIRequestAdmin(admin.ModelAdmin):
    list_display = ['owner', 'request_type', 'status', 'input_length', 'output_length', 'created_at']
    list_filter = ['request_type', 'status']
    readonly_fields = [f.name for f in AIRequest._meta.fields]

    def has_add_permission(self, request):
        return False
