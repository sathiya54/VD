import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/memory.dart';
import '../models/paginated_response.dart';

class MemoriesService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Result<PaginatedResponse<Memory>>> list({int page = 1}) async {
    try {
      final response =
          await _dio.get('memories/', queryParameters: {'page': page});
      final body = response.data;
      if (body is Map && body.containsKey('results')) {
        return Result.success(PaginatedResponse.fromJson(
            Map<String, dynamic>.from(body), Memory.fromJson));
      }
      // Fallback: plain list response.
      final rawList = ApiClient.unwrap(body) as List<dynamic>;
      return Result.success(PaginatedResponse<Memory>(
        count: rawList.length,
        results:
            rawList.map((e) => Memory.fromJson(Map<String, dynamic>.from(e))).toList(),
      ));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<Memory>> upload({
    required String title,
    required String filePath,
    required String memoryType,
    DateTime? takenAt,
  }) async {
    try {
      final form = FormData.fromMap({
        'title': title,
        'memory_type': memoryType,
        if (takenAt != null) 'taken_at': takenAt.toIso8601String(),
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('memories/', data: form);
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          Memory.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> delete(int id) async {
    try {
      await _dio.delete('memories/$id/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
