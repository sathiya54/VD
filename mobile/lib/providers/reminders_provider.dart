import 'package:flutter/foundation.dart';

import '../models/reminder.dart';
import '../services/reminders_service.dart';

class RemindersProvider extends ChangeNotifier {
  RemindersProvider({RemindersService? service})
      : _service = service ?? RemindersService();

  final RemindersService _service;

  List<Reminder> reminders = [];
  bool isLoading = false;
  String? errorMessage;

  List<Reminder> get upcoming {
    final now = DateTime.now();
    final list = reminders.where((r) => r.isActive && r.remindAt.isAfter(now)).toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
    return list;
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final result = await _service.list();
    result.when(
      success: (list) => reminders = list,
      failure: (error) => errorMessage = error.message,
    );
    isLoading = false;
    notifyListeners();
  }

  Future<Reminder?> createReminder(Reminder reminder) async {
    final result = await _service.create(reminder);
    return result.when(
      success: (created) {
        reminders = [created, ...reminders];
        notifyListeners();
        return created;
      },
      failure: (error) {
        errorMessage = error.message;
        notifyListeners();
        return null;
      },
    );
  }

  Future<Reminder?> updateReminder(int id, Reminder reminder) async {
    final result = await _service.update(id, reminder);
    return result.when(
      success: (updated) {
        reminders = reminders.map((r) => r.id == id ? updated : r).toList();
        notifyListeners();
        return updated;
      },
      failure: (error) {
        errorMessage = error.message;
        notifyListeners();
        return null;
      },
    );
  }

  Future<bool> deleteReminder(int id) async {
    final result = await _service.delete(id);
    return result.when(
      success: (_) {
        reminders = reminders.where((r) => r.id != id).toList();
        notifyListeners();
        return true;
      },
      failure: (_) => false,
    );
  }
}
