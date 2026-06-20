import 'package:dio/dio.dart';

/// API Exception Types
enum ApiExceptionType {
  timeout,
  socketException,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  internalServerError,
  noInternet,
  serverDown,
  badCertificate,
  cancel,
  sendTimeout,
  receiveTimeout,
  unknown,
}

/// Custom API Exception Model
/// Provides structured error information for all API failures
class ApiException implements Exception {
  final String message;
  final ApiExceptionType type;
  final int? statusCode;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? errorData;

  ApiException({
    required this.message,
    required this.type,
    this.statusCode,
    this.originalError,
    this.stackTrace,
    this.errorData,
  });

  /// Create ApiException from DioException
  factory ApiException.fromDioException(DioException error) {
    String message;
    ApiExceptionType type;
    int? statusCode;
    Map<String, dynamic>? errorData;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        type = ApiExceptionType.timeout;
        break;

      case DioExceptionType.receiveTimeout:
        message = 'Server took too long to respond. Please try again.';
        type = ApiExceptionType.receiveTimeout;
        break;

      case DioExceptionType.badResponse:
        statusCode = error.response?.statusCode;
        errorData = error.response?.data is Map
            ? Map<String, dynamic>.from(error.response!.data)
            : null;

        switch (statusCode) {
          case 400:
            message =
                _extractErrorMessage(error.response?.data) ??
                'Bad request. Please check your input.';
            type = ApiExceptionType.badRequest;
            break;
          case 401:
            message = 'Unauthorized. Please login again.';
            type = ApiExceptionType.unauthorized;
            break;
          case 403:
            message =
                'Forbidden. You don\'t have permission to access this resource.';
            type = ApiExceptionType.forbidden;
            break;
          case 404:
            message = 'Resource not found.';
            type = ApiExceptionType.notFound;
            break;
          case 500:
          case 502:
          case 503:
            message = 'Server error. Please try again later.';
            type = ApiExceptionType.internalServerError;
            break;
          default:
            message =
                _extractErrorMessage(error.response?.data) ??
                'Something went wrong. Please try again.';
            type = ApiExceptionType.unknown;
        }
        break;

      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        type = ApiExceptionType.cancel;
        break;

      case DioExceptionType.connectionError:
        if (error.message?.contains('SocketException') ?? false) {
          message = 'No internet connection. Please check your network.';
          type = ApiExceptionType.noInternet;
        } else if (error.message?.contains('CERTIFICATE') ?? false) {
          message = 'SSL certificate verification failed.';
          type = ApiExceptionType.badCertificate;
        } else {
          message = 'Connection error. Please check your internet connection.';
          type = ApiExceptionType.socketException;
        }
        break;

      case DioExceptionType.badCertificate:
        message = 'SSL certificate is invalid.';
        type = ApiExceptionType.badCertificate;
        break;

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          message = 'No internet connection. Please check your network.';
          type = ApiExceptionType.noInternet;
        } else {
          message = error.message ?? 'An unexpected error occurred.';
          type = ApiExceptionType.unknown;
        }
    }

    return ApiException(
      message: message,
      type: type,
      statusCode: statusCode,
      originalError: error,
      stackTrace: error.stackTrace,
      errorData: errorData,
    );
  }

  /// Create ApiException for no internet connection
  factory ApiException.noInternet() {
    return ApiException(
      message: 'No internet connection. Please check your network.',
      type: ApiExceptionType.noInternet,
    );
  }

  /// Create custom ApiException
  factory ApiException.custom({
    required String message,
    ApiExceptionType type = ApiExceptionType.unknown,
    int? statusCode,
    dynamic originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? errorData,
  }) {
    return ApiException(
      message: message,
      type: type,
      statusCode: statusCode,
      originalError: originalError,
      stackTrace: stackTrace,
      errorData: errorData,
    );
  }

  /// Extract error message from response data
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      // Try common error message keys
      final keys = ['message', 'error', 'msg', 'detail', 'description'];
      for (var key in keys) {
        if (data.containsKey(key) && data[key] is String) {
          return data[key];
        }
      }

      // Try nested error object
      if (data.containsKey('error') && data['error'] is Map) {
        return _extractErrorMessage(data['error']);
      }
    } else if (data is String) {
      return data;
    }

    return null;
  }

  /// Check if exception is due to network issues
  bool get isNetworkError =>
      type == ApiExceptionType.noInternet ||
      type == ApiExceptionType.socketException ||
      type == ApiExceptionType.timeout ||
      type == ApiExceptionType.serverDown;

  /// Check if exception is due to authentication issues
  bool get isAuthError =>
      type == ApiExceptionType.unauthorized ||
      type == ApiExceptionType.forbidden;

  /// Check if exception is due to client error (4xx)
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Check if exception is due to server error (5xx)
  bool get isServerError =>
      statusCode != null && statusCode! >= 500 && statusCode! < 600;

  /// Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'type': type.toString(),
      'statusCode': statusCode,
      'errorData': errorData,
    };
  }

  /// Convert to user-friendly string
  @override
  String toString() {
    return 'ApiException: $message (Type: $type, Status: ${statusCode ?? 'N/A'})';
  }

  /// Get detailed error information for debugging
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('ApiException Details:');
    buffer.writeln('  Message: $message');
    buffer.writeln('  Type: $type');
    buffer.writeln('  Status Code: ${statusCode ?? 'N/A'}');
    if (errorData != null) {
      buffer.writeln('  Error Data: $errorData');
    }
    if (originalError != null) {
      buffer.writeln('  Original Error: $originalError');
    }
    return buffer.toString();
  }
}
