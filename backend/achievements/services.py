from .models import Achievement, AchievementDefinition

DEFINITIONS = [
    ('first_entry', 'First Entry', 'Wrote your first diary entry.', 'edit'),
    ('entries_10', '10 Entries', 'Wrote 10 diary entries.', 'book'),
    ('entries_100', '100 Entries', 'Wrote 100 diary entries.', 'library'),
    ('streak_7', '7 Day Streak', 'Wrote every day for a week.', 'fire'),
    ('streak_30', '30 Day Streak', 'Wrote every day for a month.', 'fire'),
    ('first_goal_completed', 'Goal Getter', 'Completed your first goal.', 'flag'),
    ('goals_5', 'High Achiever', 'Completed 5 goals.', 'trophy'),


]


def ensure_definitions_exist():
    for code, title, description, icon in DEFINITIONS:
        AchievementDefinition.objects.get_or_create(
            code=code, defaults={'title': title, 'description': description, 'icon': icon},
        )


def evaluate_achievements(user):
    """Recomputes which achievements a user has earned. Cheap enough to run
    on every GET of the achievements list — counts are small per user."""
    from diary.models import DiaryEntry
    from goals.models import Goal

    ensure_definitions_exist()
    definitions = {d.code: d for d in AchievementDefinition.objects.all()}
    unlocked_codes = set(Achievement.objects.filter(owner=user).values_list('definition__code', flat=True))

    entry_count = DiaryEntry.objects.filter(owner=user, deleted_at__isnull=True).count()
    goals_completed = Goal.objects.filter(owner=user, status='completed').count()
    streak = getattr(getattr(user, 'profile', None), 'longest_streak', 0)

    to_unlock = []
    if entry_count >= 1 and 'first_entry' not in unlocked_codes:
        to_unlock.append('first_entry')
    if entry_count >= 10 and 'entries_10' not in unlocked_codes:
        to_unlock.append('entries_10')
    if entry_count >= 100 and 'entries_100' not in unlocked_codes:
        to_unlock.append('entries_100')
    if streak >= 7 and 'streak_7' not in unlocked_codes:
        to_unlock.append('streak_7')
    if streak >= 30 and 'streak_30' not in unlocked_codes:
        to_unlock.append('streak_30')
    if goals_completed >= 1 and 'first_goal_completed' not in unlocked_codes:
        to_unlock.append('first_goal_completed')
    if goals_completed >= 5 and 'goals_5' not in unlocked_codes:
        to_unlock.append('goals_5')

    for code in to_unlock:
        Achievement.objects.get_or_create(owner=user, definition=definitions[code])

    return Achievement.objects.filter(owner=user).select_related('definition')
