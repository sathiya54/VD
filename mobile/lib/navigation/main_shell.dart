import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/achievements/achievements_screen.dart';
import '../screens/ai/ai_assistant_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/diary/diary_list_screen.dart';
import '../screens/diary/trash_screen.dart';
import '../screens/goals/goals_list_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/memories/memories_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/settings/about_screen.dart';
import '../screens/settings/help_screen.dart';
import '../screens/settings/privacy_policy_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/tasks/tasks_screen.dart';

/// Scaffold with a 5-tab bottom navigation bar (Home, Diary, Calendar, Goals,
/// Profile) and a menu Drawer reachable from the app bar that lists the
/// secondary destinations from the product spec.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    DiaryListScreen(),
    CalendarScreen(),
    GoalsListScreen(),
    ProfileScreen(),
  ];

  static const _titles = ['Home', 'Diary', 'Calendar', 'Goals', 'Profile'];

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _openScreen(const NotificationsScreen()),
          ),
        ],
      ),
      drawer: _AppDrawer(onNavigate: _openScreen),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Diary'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.onNavigate});

  final void Function(Widget screen) onNavigate;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    Widget item(IconData icon, String label, Widget screen) {
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: () {
          Navigator.of(context).pop();
          onNavigate(screen);
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? 'Guest'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                child: user?.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  item(Icons.check_circle_outline, 'Tasks', const TasksScreen()),
                  item(Icons.alarm, 'Reminders', const RemindersScreen()),
                  item(Icons.photo_library_outlined, 'Memories', const MemoriesScreen()),
                  item(Icons.favorite_border, 'Favorites',
                      const DiaryListScreen(initialFavoriteOnly: true)),
                  item(Icons.bar_chart, 'Analytics', const AnalyticsScreen()),
                  item(Icons.auto_awesome_outlined, 'AI Assistant', const AiAssistantScreen()),
                  item(Icons.emoji_events_outlined, 'Achievements', const AchievementsScreen()),
                  const Divider(),
                  item(Icons.settings_outlined, 'Settings', const SettingsScreen()),
                  item(Icons.delete_outline, 'Trash', const TrashScreen()),
                  item(Icons.help_outline, 'Help', const HelpScreen()),
                  item(Icons.privacy_tip_outlined, 'Privacy', const PrivacyPolicyScreen()),
                  item(Icons.info_outline, 'About', const AboutScreen()),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Log out'),
              onTap: () async {
                Navigator.of(context).pop();
                await context.read<AuthProvider>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
