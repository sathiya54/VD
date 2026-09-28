import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/diary_entry.dart';

class AnalyticsSummary {
  final int totalEntries;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> moodDistribution;
  final Map<String, int> categoryDistribution;
  final int goalsCompleted;
  final int tasksCompleted;

  const AnalyticsSummary({
    this.totalEntries = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.moodDistribution = const {},
    this.categoryDistribution = const {},
    this.goalsCompleted = 0,
    this.tasksCompleted = 0,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    Map<String, int> toIntMap(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    return AnalyticsSummary(
      totalEntries: json['total_entries'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      moodDistribution: toIntMap(json['mood_distribution']),
      categoryDistribution: toIntMap(json['category_distribution']),
      goalsCompleted: json['goals_completed'] as int? ?? 0,
      tasksCompleted: json['tasks_completed'] as int? ?? 0,
    );
  }
}

class OnThisDayEntry {
  final int year;
  final DiaryEntry entry;
  const OnThisDayEntry({required this.year, required this.entry});

  factory OnThisDayEntry.fromJson(Map<String, dynamic> json) => OnThisDayEntry(
        year: json['year'] as int? ?? 0,
        entry: DiaryEntry.fromJson(
            Map<String, dynamic>.from(json['entry'] as Map? ?? {})),
      );
}

class AnalyticsService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Result<AnalyticsSummary>> summary() async {
    try {
      final response = await _dio.get('analytics/summary/');
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          AnalyticsSummary.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<List<OnThisDayEntry>>> onThisDay() async {
    try {
      final response = await _dio.get('analytics/on-this-day/');
      final data = ApiClient.unwrap(response.data) as List<dynamic>;
      return Result.success(data
          .map((e) => OnThisDayEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList());
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
