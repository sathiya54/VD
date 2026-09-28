import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/reminder.dart';

class RemindersService {
  final Dio _dio = ApiClient.instance.dio;

  List<Reminder> _extractList(dynamic body) {
    final rawList = body is Map && body.containsKey('results')
        ? body['results'] as List<dynamic>
        : ApiClient.unwrap(body) as List<dynamic>;
    return rawList
        .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Result<List<Reminder>>> list() async {
    try {
      final response = await _dio.get('reminders/');
      return Result.success(_extractList(response.data));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<Reminder>> create(Reminder reminder) async {
    try {
      final response =
          await _dio.post('reminders/', data: reminder.toRequestJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          Reminder.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<Reminder>> update(int id, Reminder reminder) async {
    try {
      final response =
          await _dio.patch('reminders/$id/', data: reminder.toRequestJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          Reminder.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await _dio.delete('reminders/$id/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
