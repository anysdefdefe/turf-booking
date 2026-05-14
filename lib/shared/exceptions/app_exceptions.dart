sealed class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, [this.code, this.originalError]);

  @override
  String toString() => message;
}

class AppAuthException extends AppException {
  const AppAuthException(super.message, [super.code, super.originalError]);
}

class NetworkException extends AppException {
  const NetworkException([String message = 'Please check your internet connection'])
      : super(message, 'network_error');
}

class UnknownException extends AppException {
  const UnknownException([String message = 'An unexpected error occurred. Please try again.', dynamic error])
      : super(message, 'unknown_error', error);
}
