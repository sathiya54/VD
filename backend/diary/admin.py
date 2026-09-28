from django.contrib import admin

from .models import Attachment, Category, DiaryEntry, JournalPrompt, Mood, Tag


class AttachmentInline(admin.TabularInline):
    model = Attachment
    extra = 0


@admin.register(DiaryEntry)
class DiaryEntryAdmin(admin.ModelAdmin):
    list_display = ['title', 'owner', 'date', 'mood', 'category', 'is_favorite', 'deleted_at']
    list_filter = ['is_favorite', 'is_private', 'category', 'mood', 'deleted_at']
    search_fields = ['title', 'owner__username']
    inlines = [AttachmentInline]
    date_hierarchy = 'date'


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'owner']
    list_filter = ['owner']


@admin.register(Tag)
class TagAdmin(admin.ModelAdmin):
    list_display = ['name', 'owner']


@admin.register(Mood)
class MoodAdmin(admin.ModelAdmin):
    list_display = ['name', 'emoji', 'owner', 'order']


@admin.register(JournalPrompt)
class JournalPromptAdmin(admin.ModelAdmin):
    list_display = ['text', 'is_active']
    list_editable = ['is_active']
