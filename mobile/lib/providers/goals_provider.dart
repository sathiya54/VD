import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import '../models/milestone.dart';
import '../services/goals_service.dart';

class GoalsProvider extends ChangeNotifier {
  GoalsProvider({GoalsService? service}) : _service = service ?? GoalsService();

  final GoalsService _service;

  List<Goal> goals = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final result = await _service.list();
    result.when(
      success: (list) => goals = list,
      failure: (error) => errorMessage = error.message,
    );
    isLoading = false;
    notifyListeners();
  }

  Future<Goal?> createGoal(Goal goal) async {
    final result = await _service.create(goal);
    return result.when(
      success: (created) {
        goals = [created, ...goals];
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

  Future<Goal?> updateGoal(int id, Goal goal) async {
    final result = await _service.update(id, goal);
    return result.when(
      success: (updated) {
        goals = goals.map((g) => g.id == id ? updated : g).toList();
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

  Future<bool> deleteGoal(int id) async {
    final result = await _service.delete(id);
    return result.when(
      success: (_) {
        goals = goals.where((g) => g.id != id).toList();
        notifyListeners();
        return true;
      },
      failure: (_) => false,
    );
  }

  Future<void> addMilestone(int goalId, String title) async {
    final result = await _service.addMilestone(goalId, title: title);
    result.when(
      success: (milestone) {
        goals = goals.map((g) {
          if (g.id != goalId) return g;
          return g.copyWith(milestones: [...g.milestones, milestone]);
        }).toList();
        notifyListeners();
      },
      failure: (error) => errorMessage = error.message,
    );
  }

  Future<void> toggleMilestone(int goalId, Milestone milestone) async {
    final result =
        await _service.updateMilestone(milestone.copyWith(isDone: !milestone.isDone));
    result.when(
      success: (updated) {
        goals = goals.map((g) {
          if (g.id != goalId) return g;
          final newMilestones =
              g.milestones.map((m) => m.id == updated.id ? updated : m).toList();
          return g.copyWith(milestones: newMilestones);
        }).toList();
        notifyListeners();
      },
      failure: (error) => errorMessage = error.message,
    );
  }

  Future<void> deleteMilestone(int goalId, int milestoneId) async {
    final result = await _service.deleteMilestone(milestoneId);
    result.when(
      success: (_) {
        goals = goals.map((g) {
          if (g.id != goalId) return g;
          final newMilestones =
              g.milestones.where((m) => m.id != milestoneId).toList();
          return g.copyWith(milestones: newMilestones);
        }).toList();
        notifyListeners();
      },
      failure: (_) {},
    );
  }
}
