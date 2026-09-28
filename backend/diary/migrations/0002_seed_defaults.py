from django.db import migrations

DEFAULT_CATEGORIES = [
    'Study', 'Career', 'Projects', 'Personal', 'Family',
    'Fitness', 'Ideas', 'Travel', 'Goals', 'Events',
]

DEFAULT_MOODS = [
    ('Happy', '😊'), ('Excited', '🤩'), ('Relaxed', '😌'), ('Normal', '😐'),
    ('Sad', '😔'), ('Angry', '😡'), ('Stressed', '😰'), ('Motivated', '🔥'),
    ('Tired', '😴'), ('Grateful', '🙏'),
]

DEFAULT_PROMPTS = [
    'What was the best part of your day?',
    'What is something you learned today?',
    'What are you grateful for right now?',
    'What challenge did you overcome today?',
    'What is one thing you want to improve tomorrow?',
    'Describe a moment today that made you smile.',
    'What is on your mind that you have not said out loud?',
    'What progress did you make on your goals today?',
]


def seed(apps, schema_editor):
    Category = apps.get_model('diary', 'Category')
    Mood = apps.get_model('diary', 'Mood')
    JournalPrompt = apps.get_model('diary', 'JournalPrompt')

    for name in DEFAULT_CATEGORIES:
        Category.objects.get_or_create(name=name, owner=None)

    for order, (name, emoji) in enumerate(DEFAULT_MOODS):
        Mood.objects.get_or_create(name=name, owner=None, defaults={'emoji': emoji, 'order': order})

    for text in DEFAULT_PROMPTS:
        JournalPrompt.objects.get_or_create(text=text)


def unseed(apps, schema_editor):
    Category = apps.get_model('diary', 'Category')
    Mood = apps.get_model('diary', 'Mood')
    JournalPrompt = apps.get_model('diary', 'JournalPrompt')
    Category.objects.filter(owner=None, name__in=DEFAULT_CATEGORIES).delete()
    Mood.objects.filter(owner=None, name__in=[n for n, _ in DEFAULT_MOODS]).delete()
    JournalPrompt.objects.filter(text__in=DEFAULT_PROMPTS).delete()


class Migration(migrations.Migration):
    dependencies = [('diary', '0001_initial')]
    operations = [migrations.RunPython(seed, unseed)]
