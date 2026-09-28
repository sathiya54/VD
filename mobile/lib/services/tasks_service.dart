import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/task.dart';

class TasksService {
  final Dio _dio = ApiClient.instance.dio;

  List<DiaryTask> _extractList(dynamic body) {
    final rawList = body is Map && body.containsKey('results')
        ? body['results'] as List<dynamic>
        : ApiClient.unwrap(body) as List<dynamic>;
    return rawList
        .map((e) => DiaryTask.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Result<List<DiaryTask>>> list() async {
    try {
      final response = await _dio.get('tasks/');
      return Result.success(_extractList(response.data));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryTask>> create(DiaryTask task) async {
    try {
      final response = await _dio.post('tasks/', data: task.toRequestJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          DiaryTask.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryTask>> update(int id, DiaryTask task) async {
    try {
      final response =
          await _dio.patch('tasks/$id/', data: task.toRequestJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          DiaryTask.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await _dio.delete('tasks/$id/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryTask>> toggleComplete(int id) async {
    try {
      final response = await _dio.post('tasks/$id/complete/');
      final data = ApiClient.unwrap(response.data);
      if (data is Map) {
        return Result.success(DiaryTask.fromJson(Map<String, dynamic>.from(data)));
      }
      final fresh = await _dio.get('tasks/$id/');
      return Result.success(DiaryTask.fromJson(
          Map<String, dynamic>.from(ApiClient.unwrap(fresh.data) as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
