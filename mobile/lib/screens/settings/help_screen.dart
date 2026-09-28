import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = <(String, String)>[
      (
        'How do I write a new diary entry?',
        'Tap "Write Diary" on the Home tab, or the + button on the Diary tab. Add a title, your text, a mood, an '
            'optional category, tags, and a cover photo, then save.',
      ),
      (
        'Where do deleted entries go?',
        'Deleting an entry moves it to Trash, reachable from the menu. You can restore it or delete it permanently '
            'from there.',
      ),
      (
        'How do drafts work?',
        'While writing a new entry, your text is periodically autosaved on your device. If you close the app before '
            'saving, you\'ll be offered to restore that draft the next time you open the editor.',
      ),
      (
        'Is the AI assistant required?',
        'No. AI features (auto-title, summarize, improve writing, tag suggestions) are entirely optional and off by '
            'default. Turn them on from Settings > AI Settings.',
      ),
      (
        'How do I set a reminder?',
        'Open Reminders from the menu, tap the + button, choose a title, time, and whether it repeats.',
      ),
      (
        'Can I use the app offline?',
        'You can browse previously loaded entries offline. Creating, editing, and syncing require an internet '
            'connection; the app will show a retry option if a request fails.',
      ),
      (
        'How do I delete my account?',
        'Go to Settings > Account > Delete Account. This is permanent and cannot be undone.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final (question, answer) = faqs[index];
          return ExpansionTile(
            title: Text(question, style: Theme.of(context).textTheme.titleSmall),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(answer),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
