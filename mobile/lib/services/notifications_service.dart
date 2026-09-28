import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../models/achievement.dart';
import '../models/notification.dart';
import '../models/paginated_response.dart';

class NotificationsService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Result<PaginatedResponse<AppNotification>>> list({int page = 1}) async {
    try {
      final response =
          await _dio.get('notifications/', queryParameters: {'page': page});
      return Result.success(PaginatedResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
          AppNotification.fromJson));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> markRead(int id) async {
    try {
      await _dio.post('notifications/$id/read/');
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<List<Achievement>>> achievements() async {
    try {
      final response = await _dio.get('achievements/');
      final data = ApiClient.unwrap(response.data) as List<dynamic>;
      return Result.success(data
          .map((e) => Achievement.fromJson(Map<String, dynamic>.from(e)))
          .toList());
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }
}
