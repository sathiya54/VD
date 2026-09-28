import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/diary_entry.dart';
import '../models/paginated_response.dart';
import 'diary_service.dart' show DiaryFilters;

class SearchService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Result<PaginatedResponse<DiaryEntry>>> search({
    required String query,
    int page = 1,
    DiaryFilters filters = const DiaryFilters(),
  }) async {
    try {
      final response = await _dio.get('search/', queryParameters: {
        'q': query,
        'page': page,
        ...filters.toQuery(),
      });
      return Result.success(PaginatedResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
          DiaryEntry.fromJson));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
