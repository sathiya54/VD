from django.contrib import admin

from .models import Goal, Milestone


class MilestoneInline(admin.TabularInline):
    model = Milestone
    extra = 0


@admin.register(Goal)
class GoalAdmin(admin.ModelAdmin):
    list_display = ['title', 'owner', 'priority', 'status', 'progress', 'target_date']
    list_filter = ['priority', 'status']
    search_fields = ['title', 'owner__username']
    inlines = [MilestoneInline]
