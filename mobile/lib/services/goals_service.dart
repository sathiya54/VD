import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/goal.dart';
import '../models/milestone.dart';

class GoalsService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Result<List<Goal>>> list() async {
    try {
      final response = await _dio.get('goals/');
      final body = response.data;
      final rawList = body is Map && body.containsKey('results')
          ? body['results'] as List<dynamic>
          : ApiClient.unwrap(body) as List<dynamic>;
      return Result.success(
          rawList.map((e) => Goal.fromJson(Map<String, dynamic>.from(e))).toList());
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<Goal>> getById(int id) async {
    try {
      final response = await _dio.get('goals/$id/');
      final data = ApiClient.unwrap(response.data);
      return Result.success(Goal.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<Goal>> create(Goal goal) async {
    try {
      final response = await _dio.post('goals/', data: goal.toRequestJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(Goal.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<Goal>> update(int id, Goal goal) async {
    try {
      final response = await _dio.patch('goals/$id/', data: goal.toRequestJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(Goal.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await _dio.delete('goals/$id/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<List<Milestone>>> milestones(int goalId) async {
    try {
      final response = await _dio.get('goals/$goalId/milestones/');
      final body = response.data;
      final rawList = body is Map && body.containsKey('results')
          ? body['results'] as List<dynamic>
          : ApiClient.unwrap(body) as List<dynamic>;
      return Result.success(rawList
          .map((e) => Milestone.fromJson(Map<String, dynamic>.from(e)))
          .toList());
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<Milestone>> addMilestone(
    int goalId, {
    required String title,
    int order = 0,
  }) async {
    try {
      final response = await _dio.post('goals/$goalId/milestones/', data: {
        'title': title,
        'is_done': false,
        'order': order,
      });
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          Milestone.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<Milestone>> updateMilestone(Milestone milestone) async {
    try {
      final response =
          await _dio.patch('milestones/${milestone.id}/', data: milestone.toJson());
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          Milestone.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> deleteMilestone(int id) async {
    try {
      await _dio.delete('milestones/$id/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
