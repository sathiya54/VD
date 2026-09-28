import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';

/// Wraps the optional AI endpoints. Callers should gate access behind the
/// user's `ai_enabled` profile flag; if the backend still returns a 503 with
/// error_code AI_NOT_CONFIGURED, [ApiException.isAiNotConfigured] will be true
/// so the UI can show a friendly message instead of crashing.
class AiService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Result<String>> generateTitle(String content) async {
    try {
      final response = await _dio.post('ai/title/', data: {'content': content});
      final data = ApiClient.unwrap(response.data);
      return Result.success((data as Map)['title']?.toString() ?? '');
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<String>> summarize(String content) async {
    try {
      final response =
          await _dio.post('ai/summary/', data: {'content': content});
      final data = ApiClient.unwrap(response.data);
      return Result.success((data as Map)['summary']?.toString() ?? '');
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<List<String>>> generateTags(String content) async {
    try {
      final response = await _dio.post('ai/tags/', data: {'content': content});
      final data = ApiClient.unwrap(response.data);
      final tags = (data as Map)['tags'] as List<dynamic>? ?? [];
      return Result.success(tags.map((e) => e.toString()).toList());
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<String>> improve(String content) async {
    try {
      final response =
          await _dio.post('ai/improve/', data: {'content': content});
      final data = ApiClient.unwrap(response.data);
      return Result.success((data as Map)['improved_content']?.toString() ?? '');
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
