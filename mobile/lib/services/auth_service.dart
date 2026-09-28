import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/result.dart';
import '../core/secure_storage.dart';
import '../models/user.dart';

class AuthResult {
  final String access;
  final String refresh;
  final UserProfile user;
  const AuthResult({
    required this.access,
    required this.refresh,
    required this.user,
  });
}

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Result<AuthResult>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    try {
      final response = await _dio.post('auth/register/', data: {
        'username': username,
        'email': email,
        'password': password,
        'password2': password2,
      });
      return Result.success(_parseAuthResult(response.data));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<AuthResult>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post('auth/login/', data: {
        'username': username,
        'password': password,
      });
      return Result.success(_parseAuthResult(response.data));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> logout() async {
    try {
      final refresh = await SecureStorage.instance.getRefreshToken();
      if (refresh != null) {
        await _dio.post('auth/logout/', data: {'refresh': refresh});
      }
      return const Result.success(null);
    } catch (e) {
      // Even if the server call fails, treat local logout as success.
      return const Result.success(null);
    }
  }

  Future<Result<UserProfile>> getProfile() async {
    try {
      final response = await _dio.get('auth/profile/');
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          UserProfile.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<UserProfile>> updateProfile(
    Map<String, dynamic> fields, {
    String? avatarFilePath,
  }) async {
    try {
      dynamic payload = fields;
      if (avatarFilePath != null) {
        final form = FormData.fromMap({
          ...fields,
          'avatar': await MultipartFile.fromFile(avatarFilePath),
        });
        payload = form;
      }
      final response = await _dio.patch('auth/profile/', data: payload);
      final data = ApiClient.unwrap(response.data);
      return Result.success(
          UserProfile.fromJson(Map<String, dynamic>.from(data as Map)));
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post('auth/password/change/', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  Future<Result<void>> deleteAccount(String password) async {
    try {
      await _dio.delete('auth/account/', data: {'password': password});
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ApiClient.instance.mapError(e));
    }
  }

  AuthResult _parseAuthResult(dynamic body) {
    final data = ApiClient.unwrap(body) as Map;
    return AuthResult(
      access: data['access']?.toString() ?? '',
      refresh: data['refresh']?.toString() ?? '',
      user: UserProfile.fromJson(
          Map<String, dynamic>.from(data['user'] as Map? ?? {})),
    );
  }
}
