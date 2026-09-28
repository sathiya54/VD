import 'dart:async';

import 'package:dio/dio.dart';

import 'constants.dart';
import 'result.dart';
import 'secure_storage.dart';

/// Centralized Dio-based HTTP client.
///
/// - Attaches `Authorization: Bearer <access>` to every request.
/// - On a 401, attempts a single token refresh using the refresh token and
///   retries the original request once.
/// - If the refresh also fails, clears storage and invokes [onSessionExpired]
///   so the app can navigate back to the login screen.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  /// Set by AuthProvider at app start so the interceptor can force a logout
  /// when refresh fails. Kept as a simple callback to avoid a circular
  /// dependency between core/ and providers/.
  Future<void> Function()? onSessionExpired;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  Future<bool> _refreshAccessToken() async {
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }
      final response = await Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
        ),
      ).post('auth/refresh/', data: {'refresh': refreshToken});

      final data = response.data;
      final newAccess = data is Map ? data['access'] as String? : null;
      if (newAccess == null || newAccess.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }
      await SecureStorage.instance.saveAccessToken(newAccess);
      _refreshCompleter!.complete(true);
      return true;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Normalizes any thrown error into an [ApiException].
  ApiException mapError(Object error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final body = response.data;
        String message = 'Something went wrong. Please try again.';
        String? code;
        if (body is Map) {
          message = (body['message'] ?? body['detail'] ?? message).toString();
          code = body['error_code']?.toString();
        }
        return ApiException(
          message: message,
          errorCode: code,
          statusCode: response.statusCode,
        );
      }
      // No response: network/timeout error.
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ApiException(
              message: 'The request timed out. Check your connection.');
        case DioExceptionType.connectionError:
          return const ApiException(
              message: 'Could not connect. Check your internet connection.');
        default:
          return const ApiException(message: 'Unexpected network error.');
      }
    }
    return ApiException(message: error.toString());
  }

  /// Extracts the actual payload from responses that may or may not be
  /// wrapped as {"success": true, "data": {...}}.
  static dynamic unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);
  final ApiClient _client;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    final isAuthEndpoint = requestOptions.path.contains('auth/login') ||
        requestOptions.path.contains('auth/register') ||
        requestOptions.path.contains('auth/refresh');

    if (response?.statusCode == 401 &&
        !isAuthEndpoint &&
        requestOptions.extra['retried'] != true) {
      final refreshed = await _client._refreshAccessToken();
      if (refreshed) {
        try {
          final newToken = await SecureStorage.instance.getAccessToken();
          final retryOptions = Options(
            method: requestOptions.method,
            headers: {
              ...requestOptions.headers,
              'Authorization': 'Bearer $newToken',
            },
            contentType: requestOptions.contentType,
            extra: {...requestOptions.extra, 'retried': true},
          );
          final retryResponse = await _client._dio.request(
            requestOptions.path,
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
            options: retryOptions,
          );
          handler.resolve(retryResponse);
          return;
        } catch (e) {
          // fall through to logout
        }
      }
      // Refresh failed or retry failed: force logout.
      await SecureStorage.instance.clear();
      if (_client.onSessionExpired != null) {
        await _client.onSessionExpired!();
      }
    }
    handler.next(err);
  }
}
