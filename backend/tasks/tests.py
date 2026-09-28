from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User

from .models import Task


class TaskIsolationTests(APITestCase):
    def setUp(self):
        self.user_a = User.objects.create_user(username='alice', email='alice@example.com', password='StrongPass123')
        self.user_b = User.objects.create_user(username='bob', email='bob@example.com', password='StrongPass123')
        self.task_a = Task.objects.create(owner=self.user_a, title='Alice task')

    def test_user_b_cannot_see_or_complete_user_a_task(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.get(reverse('tasks_api:task-list'))
        self.assertEqual(response.data['count'], 0)

        response = self.client.post(reverse('tasks_api:task-complete', args=[self.task_a.id]))
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.task_a.refresh_from_db()
        self.assertFalse(self.task_a.is_done)

    def test_owner_can_toggle_complete(self):
        self.client.force_authenticate(user=self.user_a)
        response = self.client.post(reverse('tasks_api:task-complete', args=[self.task_a.id]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['is_done'])
