import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/category.dart';
import '../models/diary_entry.dart';
import '../models/mood.dart';
import '../models/paginated_response.dart';
import '../models/tag.dart';

class DiaryFilters {
  final String? category;
  final String? mood;
  final String? tag;
  final bool? favorite;
  final String? search;
  final String? dateFrom;
  final String? dateTo;

  const DiaryFilters({
    this.category,
    this.mood,
    this.tag,
    this.favorite,
    this.search,
    this.dateFrom,
    this.dateTo,
  });

  Map<String, dynamic> toQuery() => {
        if (category != null) 'category': category,
        if (mood != null) 'mood': mood,
        if (tag != null) 'tag': tag,
        if (favorite != null) 'favorite': favorite,
        if (search != null && search!.isNotEmpty) 'search': search,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
      };
}

class DiaryService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Result<PaginatedResponse<DiaryEntry>>> list({
    int page = 1,
    DiaryFilters filters = const DiaryFilters(),
  }) async {
    try {
      final response = await _dio.get('entries/', queryParameters: {
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

  Future<Result<PaginatedResponse<DiaryEntry>>> trash({int page = 1}) async {
    try {
      final response =
          await _dio.get('entries/trash/', queryParameters: {'page': page});
      return Result.success(PaginatedResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
          DiaryEntry.fromJson));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryEntry>> getById(int id) async {
    try {
      final response = await _dio.get('entries/$id/');
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          DiaryEntry.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryEntry>> create(
    DiaryEntry entry, {
    List<int>? tagIds,
    String? coverImagePath,
  }) async {
    try {
      dynamic payload = entry.toRequestJson(tagIds: tagIds);
      if (coverImagePath != null) {
        payload = FormData.fromMap({
          ...entry.toRequestJson(tagIds: tagIds).map((k, v) => MapEntry(k, v?.toString())),
          'tags': (tagIds ?? entry.tags.map((t) => t.id)).map((e) => e.toString()).toList(),
          'cover_image': await MultipartFile.fromFile(coverImagePath),
        });
      }
      final response = await _dio.post('entries/', data: payload);
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          DiaryEntry.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryEntry>> update(
    int id,
    DiaryEntry entry, {
    List<int>? tagIds,
    String? coverImagePath,
  }) async {
    try {
      dynamic payload = entry.toRequestJson(tagIds: tagIds);
      if (coverImagePath != null) {
        payload = FormData.fromMap({
          ...entry.toRequestJson(tagIds: tagIds).map((k, v) => MapEntry(k, v?.toString())),
          'tags': (tagIds ?? entry.tags.map((t) => t.id)).map((e) => e.toString()).toList(),
          'cover_image': await MultipartFile.fromFile(coverImagePath),
        });
      }
      final response = await _dio.patch('entries/$id/', data: payload);
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          DiaryEntry.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  /// Soft delete (moves to trash).
  Future<Result<void>> delete(int id) async {
    try {
      await _dio.delete('entries/$id/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> permanentDelete(int id) async {
    try {
      await _dio.delete('entries/$id/permanent/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> restore(int id) async {
    try {
      await _dio.post('entries/$id/restore/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryEntry>> toggleFavorite(int id) async {
    try {
      final response = await _dio.post('entries/$id/favorite/');
      final data = ApiClient.unwrap(response.data);
      if (data is Map) {
        return Result.success(
            DiaryEntry.fromJson(Map<String, dynamic>.from(data)));
      }
      // Some backends just return {favorited: true}; fetch fresh copy.
      return getById(id);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<List<DiaryCategory>>> categories() async {
    try {
      final response = await _dio.get('categories/');
      final data = ApiClient.unwrap(response.data) as List<dynamic>;
      return Result.success(data
          .map((e) => DiaryCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList());
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<DiaryCategory>> createCategory(String name) async {
    try {
      final response = await _dio.post('categories/', data: {'name': name});
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          DiaryCategory.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<List<DiaryTag>>> tags() async {
    try {
      final response = await _dio.get('tags/');
      final data = ApiClient.unwrap(response.data) as List<dynamic>;
      return Result.success(data
          .map((e) => DiaryTag.fromJson(Map<String, dynamic>.from(e)))
          .toList());
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<List<Mood>>> moods() async {
    try {
      final response = await _dio.get('moods/');
      final data = ApiClient.unwrap(response.data) as List<dynamic>;
      return Result.success(
          data.map((e) => Mood.fromJson(Map<String, dynamic>.from(e))).toList());
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<String>> todaysPrompt() async {
    try {
      final response = await _dio.get('prompts/today/');
      final data = ApiClient.unwrap(response.data);
      return Result.success((data as Map)['text']?.toString() ?? '');
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
