import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/local_notifications.dart';
import 'core/theme.dart';
import 'navigation/app_router.dart';
import 'providers/analytics_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/diary_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/memories_provider.dart';
import 'providers/reminders_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local notification permissions are requested lazily by the plugin on
  // first use on most platforms; initialization itself is safe to run early.
  await LocalNotifications.instance.init();
  runApp(const VirtualDiaryApp());
}

class VirtualDiaryApp extends StatefulWidget {
  const VirtualDiaryApp({super.key});

  @override
  State<VirtualDiaryApp> createState() => _VirtualDiaryAppState();
}

class _VirtualDiaryAppState extends State<VirtualDiaryApp> {
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider()..load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
        ChangeNotifierProvider<DiaryProvider>(create: (_) => DiaryProvider()),
        ChangeNotifierProvider<GoalsProvider>(create: (_) => GoalsProvider()),
        ChangeNotifierProvider<TasksProvider>(create: (_) => TasksProvider()),
        ChangeNotifierProvider<RemindersProvider>(create: (_) => RemindersProvider()),
        ChangeNotifierProvider<CalendarProvider>(create: (_) => CalendarProvider()),
        ChangeNotifierProvider<MemoriesProvider>(create: (_) => MemoriesProvider()),
        ChangeNotifierProvider<AnalyticsProvider>(create: (_) => AnalyticsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}
