import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    ApiClient.instance.onSessionExpired = _handleSessionExpired;
  }

  final AuthService _authService;

  AuthStatus status = AuthStatus.unknown;
  UserProfile? user;
  bool isLoading = false;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> bootstrap() async {
    final hasTokens = await SecureStorage.instance.hasTokens();
    if (!hasTokens) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    final result = await _authService.getProfile();
    result.when(
      success: (profile) {
        user = profile;
        status = AuthStatus.authenticated;
      },
      failure: (_) {
        status = AuthStatus.unauthenticated;
      },
    );
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.login(username: username, password: password);
    return result.when(
      success: (auth) async {
        await SecureStorage.instance
            .saveTokens(accessToken: auth.access, refreshToken: auth.refresh);
        user = auth.user;
        status = AuthStatus.authenticated;
        isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (error) {
        errorMessage = error.message;
        isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String password2,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
      password2: password2,
    );
    return result.when(
      success: (auth) async {
        await SecureStorage.instance
            .saveTokens(accessToken: auth.access, refreshToken: auth.refresh);
        user = auth.user;
        status = AuthStatus.authenticated;
        isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (error) {
        errorMessage = error.message;
        isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    await SecureStorage.instance.clear();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final result = await _authService.getProfile();
    result.when(
      success: (profile) {
        user = profile;
        notifyListeners();
      },
      failure: (_) {},
    );
  }

  Future<bool> updateProfile(Map<String, dynamic> fields,
      {String? avatarFilePath}) async {
    final result =
        await _authService.updateProfile(fields, avatarFilePath: avatarFilePath);
    return result.when(
      success: (profile) {
        user = profile;
        notifyListeners();
        return true;
      },
      failure: (error) {
        errorMessage = error.message;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> _handleSessionExpired() async {
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
