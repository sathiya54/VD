from django.contrib import messages
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.views import LoginView as DjangoLoginView
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_POST

from diary.models import DiaryEntry, JournalPrompt
from diary.views import update_streak
from goals.models import Goal
from reminders.models import Reminder
from tasks.models import Task

from .forms import DiaryEntryForm, GoalForm, LoginForm, RegisterForm, TaskForm


class LoginView(DjangoLoginView):
    template_name = 'web/auth/login.html'
    authentication_form = LoginForm
    redirect_authenticated_user = True


def register_view(request):
    if request.user.is_authenticated:
        return redirect('web:dashboard')
    if request.method == 'POST':
        form = RegisterForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            messages.success(request, 'Welcome to Virtual Diary!')
            return redirect('web:dashboard')
    else:
        form = RegisterForm()
    return render(request, 'web/auth/register.html', {'form': form})


def logout_view(request):
    logout(request)
    return redirect('web:login')


@login_required
def dashboard_view(request):
    user = request.user
    today = timezone.now().date()
    prompt = JournalPrompt.objects.filter(is_active=True).order_by('?').first()
    recent_entries = DiaryEntry.objects.filter(owner=user, deleted_at__isnull=True).select_related('mood', 'category')[:5]
    todays_tasks = Task.objects.filter(owner=user, is_done=False).order_by('due_date')[:5]
    upcoming_reminders = Reminder.objects.filter(owner=user, is_active=True, remind_at__gte=timezone.now()).order_by('remind_at')[:5]
    total_entries = DiaryEntry.objects.filter(owner=user, deleted_at__isnull=True).count()

    context = {
        'today': today,
        'prompt': prompt,
        'recent_entries': recent_entries,
        'todays_tasks': todays_tasks,
        'upcoming_reminders': upcoming_reminders,
        'total_entries': total_entries,
        'profile': user.profile,
    }
    return render(request, 'web/dashboard.html', context)


@login_required
def diary_list_view(request):
    entries = DiaryEntry.objects.filter(owner=request.user, deleted_at__isnull=True).select_related('mood', 'category')
    search = request.GET.get('q')
    if search:
        entries = entries.filter(title__icontains=search)
    favorite = request.GET.get('favorite')
    if favorite:
        entries = entries.filter(is_favorite=True)
    return render(request, 'web/diary/list.html', {'entries': entries, 'search': search or ''})


@login_required
def diary_detail_view(request, pk):
    entry = get_object_or_404(DiaryEntry, pk=pk, owner=request.user, deleted_at__isnull=True)
    return render(request, 'web/diary/detail.html', {'entry': entry})


@login_required
def diary_create_view(request):
    if request.method == 'POST':
        form = DiaryEntryForm(request.POST, request.FILES, user=request.user)
        if form.is_valid():
            entry = form.save_with_tags(request.user)
            update_streak(request.user, entry.date)
            messages.success(request, 'Entry saved.')
            return redirect('web:diary-detail', pk=entry.pk)
    else:
        form = DiaryEntryForm(user=request.user, initial={'date': timezone.now().date()})
    return render(request, 'web/diary/form.html', {'form': form, 'is_new': True})


@login_required
def diary_edit_view(request, pk):
    entry = get_object_or_404(DiaryEntry, pk=pk, owner=request.user, deleted_at__isnull=True)
    if request.method == 'POST':
        form = DiaryEntryForm(request.POST, request.FILES, instance=entry, user=request.user)
        if form.is_valid():
            form.save_with_tags(request.user)
            messages.success(request, 'Entry updated.')
            return redirect('web:diary-detail', pk=entry.pk)
    else:
        form = DiaryEntryForm(instance=entry, user=request.user)
    return render(request, 'web/diary/form.html', {'form': form, 'is_new': False, 'entry': entry})


@login_required
def diary_delete_view(request, pk):
    entry = get_object_or_404(DiaryEntry, pk=pk, owner=request.user, deleted_at__isnull=True)
    if request.method == 'POST':
        entry.soft_delete()
        update_streak(request.user)
        messages.info(request, 'Entry moved to trash.')
        return redirect('web:diary-list')
    return render(request, 'web/diary/confirm_delete.html', {'entry': entry})


@login_required
def diary_favorite_toggle(request, pk):
    entry = get_object_or_404(DiaryEntry, pk=pk, owner=request.user)
    entry.is_favorite = not entry.is_favorite
    entry.version += 1
    entry.save(update_fields=['is_favorite', 'version'])
    return redirect(request.META.get('HTTP_REFERER') or 'web:diary-list')


@login_required
def trash_view(request):
    entries = DiaryEntry.objects.filter(owner=request.user, deleted_at__isnull=False)
    return render(request, 'web/diary/trash.html', {'entries': entries})


@login_required
@require_POST
def trash_restore_view(request, pk):
    entry = get_object_or_404(DiaryEntry, pk=pk, owner=request.user, deleted_at__isnull=False)
    entry.restore()
    messages.success(request, 'Entry restored.')
    return redirect('web:trash')


@login_required
@require_POST
def trash_permanent_delete_view(request, pk):
    entry = get_object_or_404(DiaryEntry, pk=pk, owner=request.user)
    entry.delete()
    messages.info(request, 'Entry permanently deleted.')
    return redirect('web:trash')


@login_required
def goals_list_view(request):
    goals = Goal.objects.filter(owner=request.user).prefetch_related('milestones')
    return render(request, 'web/goals/list.html', {'goals': goals})


@login_required
def goal_create_view(request):
    if request.method == 'POST':
        form = GoalForm(request.POST)
        if form.is_valid():
            goal = form.save(commit=False)
            goal.owner = request.user
            goal.save()
            return redirect('web:goals-list')
    else:
        form = GoalForm()
    return render(request, 'web/goals/form.html', {'form': form})


@login_required
def tasks_list_view(request):
    tasks = Task.objects.filter(owner=request.user)
    if request.method == 'POST':
        form = TaskForm(request.POST, user=request.user)
        if form.is_valid():
            task = form.save(commit=False)
            task.owner = request.user
            task.save()
            return redirect('web:tasks-list')
    else:
        form = TaskForm(user=request.user)
    return render(request, 'web/tasks/list.html', {'tasks': tasks, 'form': form})


@login_required
def task_toggle_view(request, pk):
    task = get_object_or_404(Task, pk=pk, owner=request.user)
    task.is_done = not task.is_done
    task.save(update_fields=['is_done', 'updated_at'])
    return redirect('web:tasks-list')


@login_required
def profile_view(request):
    profile = request.user.profile
    if request.method == 'POST':
        profile.ai_enabled = 'ai_enabled' in request.POST
        profile.dark_mode_pref = request.POST.get('dark_mode_pref', profile.dark_mode_pref)
        profile.bio = request.POST.get('bio', profile.bio)
        profile.save()
        messages.success(request, 'Settings updated.')
        return redirect('web:profile')
    return render(request, 'web/profile.html', {'profile': profile})


def privacy_policy_view(request):
    return render(request, 'web/privacy.html')


def about_view(request):
    return render(request, 'web/about.html')


def help_view(request):
    return render(request, 'web/help.html')
