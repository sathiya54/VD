/// A small Result type used across services so providers/UI can handle
/// success/failure without try/catch scattered everywhere.
library;

class ApiException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.errorCode,
    this.statusCode,
  });

  bool get isAiNotConfigured => errorCode == 'AI_NOT_CONFIGURED';
  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isNetworkError => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode, $errorCode, $message)';
}

sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(ApiException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  ApiException? get errorOrNull =>
      this is Failure<T> ? (this as Failure<T>).error : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Failure<T>) return failure(self.error);
    throw StateError('Unknown Result subtype');
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final ApiException error;
  const Failure(this.error);
}
