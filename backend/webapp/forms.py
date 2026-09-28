from django import forms
from django.contrib.auth.forms import AuthenticationForm

from accounts.models import User
from diary.models import Category, DiaryEntry, Mood, Tag
from goals.models import Goal
from tasks.models import Task


class LoginForm(AuthenticationForm):
    username = forms.CharField(widget=forms.TextInput(attrs={'class': 'form-control', 'autofocus': True}))
    password = forms.CharField(widget=forms.PasswordInput(attrs={'class': 'form-control'}))


class RegisterForm(forms.ModelForm):
    password = forms.CharField(widget=forms.PasswordInput(attrs={'class': 'form-control'}))
    password2 = forms.CharField(label='Confirm password', widget=forms.PasswordInput(attrs={'class': 'form-control'}))

    class Meta:
        model = User
        fields = ['username', 'email']
        widgets = {
            'username': forms.TextInput(attrs={'class': 'form-control'}),
            'email': forms.EmailInput(attrs={'class': 'form-control'}),
        }

    def clean(self):
        cleaned = super().clean()
        if cleaned.get('password') != cleaned.get('password2'):
            raise forms.ValidationError('Passwords do not match.')
        return cleaned

    def save(self, commit=True):
        user = super().save(commit=False)
        user.set_password(self.cleaned_data['password'])
        if commit:
            user.save()
        return user


class DiaryEntryForm(forms.ModelForm):
    tags_input = forms.CharField(
        required=False, label='Tags (comma separated)',
        widget=forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'python, django, project'}),
    )

    class Meta:
        model = DiaryEntry
        fields = ['title', 'content', 'date', 'time', 'mood', 'category', 'cover_image', 'is_favorite', 'is_private']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'content': forms.Textarea(attrs={'class': 'form-control', 'id': 'id_content_editor_source', 'rows': 10}),
            'date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'time': forms.TimeInput(attrs={'class': 'form-control', 'type': 'time'}),
            'mood': forms.Select(attrs={'class': 'form-select'}),
            'category': forms.Select(attrs={'class': 'form-select'}),
            'cover_image': forms.ClearableFileInput(attrs={'class': 'form-control'}),
            'is_favorite': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'is_private': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

    def __init__(self, *args, user=None, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['mood'].queryset = Mood.objects.filter(models_q_owner(user))
        self.fields['category'].queryset = Category.objects.filter(models_q_owner(user))
        if self.instance.pk:
            self.fields['tags_input'].initial = ', '.join(self.instance.tags.values_list('name', flat=True))

    def save_with_tags(self, user):
        entry = self.save(commit=False)
        entry.owner = user
        if entry.pk:
            entry.version += 1
        entry.save()
        tag_names = [t.strip() for t in self.cleaned_data.get('tags_input', '').split(',') if t.strip()]
        tags = []
        for name in tag_names:
            tag, _ = Tag.objects.get_or_create(owner=user, name=name)
            tags.append(tag)
        entry.tags.set(tags)
        return entry


def models_q_owner(user):
    from django.db.models import Q
    return Q(owner=user) | Q(owner__isnull=True)


class GoalForm(forms.ModelForm):
    class Meta:
        model = Goal
        fields = ['title', 'description', 'start_date', 'target_date', 'priority', 'progress', 'status']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'start_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'target_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'priority': forms.Select(attrs={'class': 'form-select'}),
            'progress': forms.NumberInput(attrs={'class': 'form-control', 'min': 0, 'max': 100}),
            'status': forms.Select(attrs={'class': 'form-select'}),
        }


class TaskForm(forms.ModelForm):
    class Meta:
        model = Task
        fields = ['title', 'description', 'due_date', 'priority', 'goal']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 2}),
            'due_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'priority': forms.Select(attrs={'class': 'form-select'}),
            'goal': forms.Select(attrs={'class': 'form-select'}),
        }

    def __init__(self, *args, user=None, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['goal'].queryset = Goal.objects.filter(owner=user)
        self.fields['goal'].required = False
