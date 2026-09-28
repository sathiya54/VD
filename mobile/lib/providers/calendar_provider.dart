import 'package:flutter/foundation.dart';

import '../services/events_service.dart';
import '../models/event.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider({EventsService? service}) : _service = service ?? EventsService();

  final EventsService _service;

  int currentYear = DateTime.now().year;
  int currentMonth = DateTime.now().month;

  List<dynamic> entries = [];
  List<dynamic> tasks = [];
  List<dynamic> goals = [];
  List<dynamic> reminders = [];
  List<dynamic> events = [];

  bool isLoading = false;
  String? errorMessage;

  Future<void> loadMonth({int? year, int? month}) async {
    currentYear = year ?? currentYear;
    currentMonth = month ?? currentMonth;
    isLoading = true;
    notifyListeners();

    final result =
        await _service.monthView(year: currentYear, month: currentMonth);
    result.when(
      success: (data) {
        entries = data['entries'] ?? [];
        tasks = data['tasks'] ?? [];
        goals = data['goals'] ?? [];
        reminders = data['reminders'] ?? [];
        events = data['events'] ?? [];
      },
      failure: (error) => errorMessage = error.message,
    );
    isLoading = false;
    notifyListeners();
  }

  /// Returns all item maps that fall on the given day, tagged with a `kind`.
  List<Map<String, dynamic>> itemsForDay(DateTime day) {
    String dayStr =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    bool matches(dynamic item) {
      final raw = (item['date'] ?? item['datetime'] ?? item['due_date'] ??
              item['start_datetime'] ?? item['remind_at'] ?? '')
          .toString();
      return raw.startsWith(dayStr);
    }

    final result = <Map<String, dynamic>>[];
    for (final e in entries) {
      if (matches(e)) result.add({...Map<String, dynamic>.from(e), 'kind': 'entry'});
    }
    for (final t in tasks) {
      if (matches(t)) result.add({...Map<String, dynamic>.from(t), 'kind': 'task'});
    }
    for (final g in goals) {
      if (matches(g)) result.add({...Map<String, dynamic>.from(g), 'kind': 'goal'});
    }
    for (final r in reminders) {
      if (matches(r)) result.add({...Map<String, dynamic>.from(r), 'kind': 'reminder'});
    }
    for (final ev in events) {
      if (matches(ev)) result.add({...Map<String, dynamic>.from(ev), 'kind': 'event'});
    }
    return result;
  }

  Future<bool> createEvent(DiaryEvent event) async {
    final result = await _service.create(event);
    return result.when(
      success: (_) {
        loadMonth();
        return true;
      },
      failure: (error) {
        errorMessage = error.message;
        notifyListeners();
        return false;
      },
    );
  }
}
