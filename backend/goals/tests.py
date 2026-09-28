from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import User

from .models import Goal


class GoalIsolationTests(APITestCase):
    def setUp(self):
        self.user_a = User.objects.create_user(username='alice', email='alice@example.com', password='StrongPass123')
        self.user_b = User.objects.create_user(username='bob', email='bob@example.com', password='StrongPass123')
        self.goal_a = Goal.objects.create(owner=self.user_a, title='Alice goal')

    def test_user_b_cannot_see_or_edit_user_a_goal(self):
        self.client.force_authenticate(user=self.user_b)
        response = self.client.get(reverse('goals_api:goal-list'))
        self.assertEqual(response.data['count'], 0)

        response = self.client.patch(reverse('goals_api:goal-detail', args=[self.goal_a.id]), {'title': 'hacked'})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_owner_can_add_milestone(self):
        self.client.force_authenticate(user=self.user_a)
        response = self.client.post(reverse('goals_api:goal-milestones', args=[self.goal_a.id]), {'title': 'Step 1'})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(self.goal_a.milestones.count(), 1)
