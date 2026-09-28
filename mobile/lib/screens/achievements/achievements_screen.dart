import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../services/notifications_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_indicator.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _service = NotificationsService();
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await _service.achievements();
    result.when(
      success: (list) => setState(() => _achievements = list),
      failure: (error) => setState(() => _error = error.message),
    );
    setState(() => _isLoading = false);
  }

  IconData _iconFor(String? name) {
    switch (name) {
      case 'streak':
        return Icons.local_fire_department;
      case 'entries':
        return Icons.book;
      case 'goals':
        return Icons.flag;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const LoadingIndicator();
    } else if (_error != null && _achievements.isEmpty) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else if (_achievements.isEmpty) {
      body = const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No achievements yet',
        message: 'Keep journaling and completing goals to unlock badges.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: _achievements.length,
          itemBuilder: (context, index) {
            final achievement = _achievements[index];
            final unlocked = achievement.isUnlocked;
            return Card(
              color: unlocked ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _iconFor(achievement.icon),
                      size: 40,
                      color: unlocked
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: body,
    );
  }
}
