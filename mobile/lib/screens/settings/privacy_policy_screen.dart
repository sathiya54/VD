import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        );
    Widget body(String text) => Text(text, style: theme.textTheme.bodyMedium);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your privacy matters. This page explains what Virtual Diary collects, why, and the choices you have.',
            style: theme.textTheme.bodyLarge,
          ),
          heading('What we collect'),
          body(
            'Account details (username, email, and password hash), the diary entries, moods, tags, categories, goals, '
            'tasks, reminders, calendar events, and memory files (photos/documents) you choose to create, and basic '
            'usage data such as your entry streak and completion counts used to power your personal analytics.',
          ),
          heading('Why we collect it'),
          body(
            'We use your data solely to provide the features you use: storing and syncing your journal across your '
            'devices, showing your streaks and analytics, sending reminder notifications you set, and letting you '
            'search and organize your own entries. We do not sell your personal data or diary content to third parties.',
          ),
          heading('AI processing is optional'),
          body(
            'Virtual Diary includes optional AI features (auto-titling, summarizing, improving writing, and tag '
            'suggestions). These are OFF by default. If you turn AI features on in Settings, the text you explicitly '
            'submit to an AI action is sent to our AI processing service only for that single request, purely to '
            'generate the result you asked for. You can disable AI features at any time, and disabling them stops any '
            'further processing of your content by the AI service.',
          ),
          heading('Your control over your data'),
          body(
            'You can edit or delete any diary entry, task, goal, reminder, or memory at any time. Deleted diary '
            'entries move to Trash first so you can restore them, and are permanently removed either after you empty '
            'the trash or after the retention window elapses. Memory files you delete are removed from storage.',
          ),
          heading('Account deletion'),
          body(
            'You can permanently delete your account at any time from Settings > Account > Delete Account. This '
            'immediately and irreversibly deletes your profile, diary entries, goals, tasks, reminders, events, '
            'memories, and analytics history. We recommend exporting a backup first if you want to keep a copy.',
          ),
          heading('Security'),
          body(
            'Authentication tokens are stored using your device\'s secure, encrypted storage rather than plain app '
            'preferences. All requests to our servers are made over encrypted connections.',
          ),
          heading('Contact'),
          body(
            'Questions about this policy or your data can be sent through the Help screen in the app.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
