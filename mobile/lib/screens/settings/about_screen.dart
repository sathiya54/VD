import 'package:flutter/material.dart';

import '../../core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Icon(Icons.menu_book_rounded, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              AppConstants.appName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Center(
            child: Text('Version 1.0.0', style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 24),
          Text(
            'Virtual Diary is your AI-powered personal journal and life-management companion. Capture your day, '
            'track your mood, set and follow through on goals, manage tasks and reminders, keep a calendar of what '
            'matters, and hold on to memories in one private place.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Optional AI features can help you title, summarize, tag, and polish your entries -- always under your '
            'control and off by default.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Built with Flutter'),
          ),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Backend: Django REST Framework'),
          ),
        ],
      ),
    );
  }
}
