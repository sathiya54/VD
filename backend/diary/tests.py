from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User

from .models import Category, DiaryEntry, Mood


class DiaryCrudTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='writer', email='writer@example.com', password='StrongPass123')
        self.client.force_authenticate(user=self.user)
        self.category = Category.objects.create(name='Personal', owner=None)
        self.mood = Mood.objects.create(name='Happy', emoji='😊', owner=None)

    def test_create_list_and_retrieve_entry(self):
        response = self.client.post(reverse('diary_api:entry-list'), {
            'title': 'My day', 'content': 'It was good.', 'date': '2026-01-01',
            'category': self.category.id, 'mood': self.mood.id,
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        entry_id = response.data['id']

        response = self.client.get(reverse('diary_api:entry-list'))
        self.assertEqual(response.data['count'], 1)

        response = self.client.get(reverse('diary_api:entry-detail', args=[entry_id]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'My day')

    def test_delete_is_soft_and_appears_in_trash(self):
        entry = DiaryEntry.objects.create(owner=self.user, title='Temp', date='2026-01-01')

        response = self.client.delete(reverse('diary_api:entry-detail', args=[entry.id]))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

        entry.refresh_from_db()
        self.assertIsNotNone(entry.deleted_at)

        response = self.client.get(reverse('diary_api:entry-list'))
        self.assertEqual(response.data['count'], 0)

        response = self.client.get(reverse('diary_api:entry-trash'))
        self.assertEqual(response.data['count'], 1)

    def test_restore_and_permanent_delete(self):
        entry = DiaryEntry.objects.create(owner=self.user, title='Temp', date='2026-01-01')
        entry.soft_delete()

        response = self.client.post(reverse('diary_api:entry-restore', args=[entry.id]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        entry.refresh_from_db()
        self.assertIsNone(entry.deleted_at)

        response = self.client.delete(reverse('diary_api:entry-permanent-delete', args=[entry.id]))
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(DiaryEntry.objects.filter(id=entry.id).exists())

    def test_favorite_toggle(self):
        entry = DiaryEntry.objects.create(owner=self.user, title='Temp', date='2026-01-01')
        response = self.client.post(reverse('diary_api:entry-favorite', args=[entry.id]))
        self.assertTrue(response.data['is_favorite'])
        response = self.client.post(reverse('diary_api:entry-favorite', args=[entry.id]))
        self.assertFalse(response.data['is_favorite'])

    def test_search_filters_by_title(self):
        DiaryEntry.objects.create(owner=self.user, title='Django progress', content='', date='2026-01-01')
        DiaryEntry.objects.create(owner=self.user, title='Grocery list', content='', date='2026-01-02')

        response = self.client.get(reverse('search_api:search'), {'q': 'Django'})
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['title'], 'Django progress')


class DiaryIsolationTests(APITestCase):
    """The most important test in the project: User A must never be able to
    read, modify or delete User B's diary data through the API."""

    def setUp(self):
        self.user_a = User.objects.create_user(username='alice', email='alice@example.com', password='StrongPass123')
        self.user_b = User.objects.create_user(username='bob', email='bob@example.com', password='StrongPass123')
        self.entry_a = DiaryEntry.objects.create(owner=self.user_a, title='Alice private entry', date='2026-01-01')

    def test_user_b_cannot_see_user_a_entry_in_list(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.get(reverse('diary_api:entry-list'))
        self.assertEqual(response.data['count'], 0)

    def test_user_b_cannot_retrieve_user_a_entry_by_id(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.get(reverse('diary_api:entry-detail', args=[self.entry_a.id]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_user_b_cannot_update_user_a_entry(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.patch(reverse('diary_api:entry-detail', args=[self.entry_a.id]), {'title': 'hacked'})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.entry_a.refresh_from_db()
        self.assertEqual(self.entry_a.title, 'Alice private entry')

    def test_user_b_cannot_delete_user_a_entry(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.delete(reverse('diary_api:entry-detail', args=[self.entry_a.id]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(DiaryEntry.objects.filter(id=self.entry_a.id, deleted_at__isnull=True).exists())

    def test_anonymous_user_cannot_access_entries(self):
        response = self.client.get(reverse('diary_api:entry-list'))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
