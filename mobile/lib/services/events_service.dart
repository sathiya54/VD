import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/event.dart';

class EventsService {
  final Dio _dio = ApiClient.instance.dio;

  List<DiaryEvent> _extractList(dynamic body) {
    final rawList = body is Map && body.containsKey('results')
        ? body['results'] as List<dynamic>
        : ApiClient.unwrap(body) as List<dynamic>;
    return rawList
        .map((e) => DiaryEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Result<List<DiaryEvent>>> list() async {
    try {
      final response = await _dio.get('events/');
      return Result.success(_extractList(response.data));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryEvent>> create(DiaryEvent event) async {
    try {
      final response = await _dio.post('events/', data: event.toRequestJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          DiaryEvent.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryEvent>> update(int id, DiaryEvent event) async {
    try {
      final response =
          await _dio.patch('events/$id/', data: event.toRequestJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          DiaryEvent.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await _dio.delete('events/$id/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  /// GET calendar/?year=&month= -> {entries, tasks, goals, reminders, events}
  Future<Result<Map<String, List<dynamic>>>> monthView({
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.get('calendar/', queryParameters: {
        'year': year,
        'month': month,
      });
      final data =
          Map<String, dynamic>.from(ApiClient.unwrap(response.data) as Map);
      return Result.success({
        'entries': (data['entries'] as List<dynamic>? ?? []),
        'tasks': (data['tasks'] as List<dynamic>? ?? []),
        'goals': (data['goals'] as List<dynamic>? ?? []),
        'reminders': (data['reminders'] as List<dynamic>? ?? []),
        'events': (data['events'] as List<dynamic>? ?? []),
      });
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
