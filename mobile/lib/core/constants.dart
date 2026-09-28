/// App-wide constants: API environment configuration and static option lists
/// that mirror the fixed backend contract (moods/categories/priorities are
/// still fetched from the API where possible; these are fallbacks/labels).
library;

/// Which backend environment the app is built against.
enum ApiEnvironment { dev, prod }

class ApiConfig {
  ApiConfig._();

  /// Flip this to switch build targets. In a real CI setup this would be
  /// provided via --dart-define instead of a hardcoded flag.
  static const ApiEnvironment environment = ApiEnvironment.dev;

  /// Android emulator maps 10.0.2.2 to the host machine's localhost.
  /// - Android emulator (dev): http://10.0.2.2:8000/api/v1/
  /// - iOS simulator (dev):    http://localhost:8000/api/v1/
  /// - Physical device (dev):  http://<your-lan-ip>:8000/api/v1/
  /// - Production:             https://api.yourdomain.com/api/v1/
  static const String devBaseUrl = 'http://10.0.2.2:8000/api/v1/';
  static const String prodBaseUrl = 'https://api.yourdomain.com/api/v1/';

  static String get baseUrl {
    switch (environment) {
      case ApiEnvironment.dev:
        return devBaseUrl;
      case ApiEnvironment.prod:
        return prodBaseUrl;
    }
  }

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class AppConstants {
  AppConstants._();

  static const String appName = 'Virtual Diary';

  static const int pageSize = 20;

  // Fallback mood list matching the 10 seeded backend defaults.
  // The live list should be fetched from GET moods/ whenever possible.
  static const List<Map<String, String>> defaultMoods = [
    {'name': 'Happy', 'emoji': '😊'},
    {'name': 'Excited', 'emoji': '🤩'},
    {'name': 'Relaxed', 'emoji': '😌'},
    {'name': 'Normal', 'emoji': '😐'},
    {'name': 'Sad', 'emoji': '😔'},
    {'name': 'Angry', 'emoji': '😡'},
    {'name': 'Stressed', 'emoji': '😰'},
    {'name': 'Motivated', 'emoji': '🔥'},
    {'name': 'Tired', 'emoji': '😴'},
    {'name': 'Grateful', 'emoji': '🙏'},
  ];

  static const List<String> defaultCategories = [
    'Personal',
    'Work',
    'Health',
    'Travel',
    'Relationships',
    'Ideas',
  ];

  static const List<String> priorities = ['low', 'medium', 'high'];

  static const List<String> goalStatuses = [
    'not_started',
    'in_progress',
    'completed',
    'abandoned',
  ];

  static const List<String> repeatOptions = [
    'one_time',
    'daily',
    'weekly',
    'monthly',
  ];

  static const List<String> memoryTypes = [
    'photo',
    'document',
    'screenshot',
    'certificate',
    'project_file',
  ];

  static const List<String> darkModePrefs = ['light', 'dark', 'system'];

  // Local (non-secure) storage keys.
  static const String draftStorageKey = 'diary_draft_v1';
  static const String themePrefKey = 'theme_pref_v1';
}
