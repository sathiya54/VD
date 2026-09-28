import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/diary_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/streak_badge.dart';
import '../diary/diary_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AnalyticsProvider>().load();
        context.read<DiaryProvider>().loadMeta();
        context.read<TasksProvider>().load();
        context.read<RemindersProvider>().load();
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final analytics = context.watch<AnalyticsProvider>();
    final diary = context.watch<DiaryProvider>();
    final tasks = context.watch<TasksProvider>();
    final reminders = context.watch<RemindersProvider>();
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<AnalyticsProvider>().load(),
          context.read<TasksProvider>().load(),
          context.read<RemindersProvider>().load(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_greeting()} 👋',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            auth.user?.displayName ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StreakBadge(days: analytics.summary.currentStreak),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  label: 'Entries',
                  value: analytics.summary.totalEntries.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.14),
                  theme.colorScheme.primary.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Prompt", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    diary.todaysPrompt?.isNotEmpty == true
                        ? diary.todaysPrompt!
                        : 'What made you smile today?',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DiaryEditorScreen()),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Write Diary'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text("Today's Tasks", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (tasks.todaysTasks.isEmpty)
            _EmptyRow(text: 'No tasks due today.')
          else
            ...tasks.todaysTasks.map(
              (task) => Card(
                child: CheckboxListTile(
                  value: task.isDone,
                  onChanged: (_) => context.read<TasksProvider>().toggleComplete(task.id),
                  title: Text(
                    task.title,
                    style: TextStyle(
                        decoration: task.isDone ? TextDecoration.lineThrough : null),
                  ),
                  subtitle: task.dueDate != null ? Text('Due ${task.dueDate}') : null,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Upcoming', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (reminders.upcoming.isEmpty)
            _EmptyRow(text: 'Nothing scheduled. Enjoy the calm!')
          else
            ...reminders.upcoming.take(5).map(
                  (reminder) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(reminder.title),
                      subtitle: Text(
                        DateFormat('MMM d, h:mm a').format(reminder.remindAt),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
