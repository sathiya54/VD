import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/tasks_service.dart';

class TasksProvider extends ChangeNotifier {
  TasksProvider({TasksService? service}) : _service = service ?? TasksService();

  final TasksService _service;

  List<DiaryTask> tasks = [];
  bool isLoading = false;
  String? errorMessage;

  List<DiaryTask> get todaysTasks {
    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return tasks.where((t) => t.dueDate == todayStr).toList();
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final result = await _service.list();
    result.when(
      success: (list) => tasks = list,
      failure: (error) => errorMessage = error.message,
    );
    isLoading = false;
    notifyListeners();
  }

  Future<DiaryTask?> createTask(DiaryTask task) async {
    final result = await _service.create(task);
    return result.when(
      success: (created) {
        tasks = [created, ...tasks];
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

  Future<DiaryTask?> updateTask(int id, DiaryTask task) async {
    final result = await _service.update(id, task);
    return result.when(
      success: (updated) {
        tasks = tasks.map((t) => t.id == id ? updated : t).toList();
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

  Future<bool> deleteTask(int id) async {
    final result = await _service.delete(id);
    return result.when(
      success: (_) {
        tasks = tasks.where((t) => t.id != id).toList();
        notifyListeners();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<void> toggleComplete(int id) async {
    // Optimistic update.
    final index = tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final original = tasks[index];
    tasks[index] = original.copyWith(isDone: !original.isDone);
    notifyListeners();

    final result = await _service.toggleComplete(id);
    result.when(
      success: (updated) {
        tasks = tasks.map((t) => t.id == id ? updated : t).toList();
        notifyListeners();
      },
      failure: (error) {
        // revert on failure
        tasks = tasks.map((t) => t.id == id ? original : t).toList();
        errorMessage = error.message;
        notifyListeners();
      },
    );
  }
}
