import 'api_exception.dart';

/// Response Status
enum ResponseStatus { success, error }

/// Generic API Response Wrapper
/// Provides structured response with generic type support
class ApiResponse<T> {
  /// Parsed data of generic type T
  final T? data;

  /// Raw response data (JSON)
  final dynamic raw;

  /// Response status (success/error)
  final ResponseStatus status;

  /// Error information (null if success)
  final ApiException? error;

  /// HTTP status code
  final int? statusCode;

  /// Response headers
  final Map<String, dynamic>? headers;

  /// Response message
  final String? message;

  /// Request duration
  final Duration? duration;

  ApiResponse({
    this.data,
    this.raw,
    required this.status,
    this.error,
    this.statusCode,
    this.headers,
    this.message,
    this.duration,
  });

  /// Create success response
  factory ApiResponse.success({
    T? data,
    dynamic raw,
    int? statusCode,
    Map<String, dynamic>? headers,
    String? message,
    Duration? duration,
  }) {
    return ApiResponse<T>(
      data: data,
      raw: raw,
      status: ResponseStatus.success,
      statusCode: statusCode,
      headers: headers,
      message: message,
      duration: duration,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    required ApiException error,
    dynamic raw,
    int? statusCode,
    Map<String, dynamic>? headers,
    Duration? duration,
  }) {
    return ApiResponse<T>(
      raw: raw,
      status: ResponseStatus.error,
      error: error,
      statusCode: statusCode,
      headers: headers,
      message: error.message,
      duration: duration,
    );
  }

  /// Check if response is successful
  bool get isSuccess => status == ResponseStatus.success && error == null;

  /// Check if response is error
  bool get isError => status == ResponseStatus.error || error != null;

  /// Check if status code is 2xx
  bool get isStatusSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  /// Get data or throw error
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    } else if (error != null) {
      throw error!;
    } else {
      throw ApiException.custom(
        message: 'No data available',
        type: ApiExceptionType.unknown,
      );
    }
  }

  /// Get data or return default value
  T dataOrDefault(T defaultValue) {
    return data ?? defaultValue;
  }

  /// Get data or return null
  T? get dataOrNull => data;

  /// Execute callback on success
  ApiResponse<T> onSuccess(void Function(T? data) callback) {
    if (isSuccess) {
      callback(data);
    }
    return this;
  }

  /// Execute callback on error
  ApiResponse<T> onError(void Function(ApiException error) callback) {
    if (isError && error != null) {
      callback(error!);
    }
    return this;
  }

  /// Transform data to another type
  ApiResponse<R> transform<R>(R Function(T? data) transformer) {
    if (isSuccess) {
      return ApiResponse<R>.success(
        data: transformer(data),
        raw: raw,
        statusCode: statusCode,
        headers: headers,
        message: message,
        duration: duration,
      );
    } else {
      return ApiResponse<R>.error(
        error: error!,
        raw: raw,
        statusCode: statusCode,
        headers: headers,
        duration: duration,
      );
    }
  }

  /// Map response to another type
  ApiResponse<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return ApiResponse<R>.success(
          data: mapper(data as T),
          raw: raw,
          statusCode: statusCode,
          headers: headers,
          message: message,
          duration: duration,
        );
      } catch (e) {
        return ApiResponse<R>.error(
          error: ApiException.custom(
            message: 'Failed to map response: ${e.toString()}',
            type: ApiExceptionType.unknown,
          ),
          raw: raw,
          statusCode: statusCode,
          headers: headers,
          duration: duration,
        );
      }
    } else {
      return ApiResponse<R>.error(
        error:
            error ??
            ApiException.custom(
              message: 'No data to map',
              type: ApiExceptionType.unknown,
            ),
        raw: raw,
        statusCode: statusCode,
        headers: headers,
        duration: duration,
      );
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'status': status.toString(),
      'statusCode': statusCode,
      'message': message,
      'data': data,
      'raw': raw,
      'error': error?.toJson(),
      'duration': duration?.inMilliseconds,
    };
  }

  /// Convert to string
  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResponse.success(statusCode: $statusCode, message: $message)';
    } else {
      return 'ApiResponse.error(statusCode: $statusCode, error: ${error?.message})';
    }
  }

  /// Get detailed string representation
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('ApiResponse:');
    buffer.writeln('  Status: $status');
    buffer.writeln('  Status Code: ${statusCode ?? 'N/A'}');
    buffer.writeln('  Message: ${message ?? 'N/A'}');
    buffer.writeln('  Duration: ${duration?.inMilliseconds ?? 'N/A'}ms');

    if (isSuccess) {
      buffer.writeln('  Data Type: ${T.toString()}');
      buffer.writeln('  Has Data: ${data != null}');
    } else {
      buffer.writeln('  Error: ${error?.message ?? 'N/A'}');
      buffer.writeln('  Error Type: ${error?.type ?? 'N/A'}');
    }

    return buffer.toString();
  }

  /// Copy with new values
  ApiResponse<T> copyWith({
    T? data,
    dynamic raw,
    ResponseStatus? status,
    ApiException? error,
    int? statusCode,
    Map<String, dynamic>? headers,
    String? message,
    Duration? duration,
  }) {
    return ApiResponse<T>(
      data: data ?? this.data,
      raw: raw ?? this.raw,
      status: status ?? this.status,
      error: error ?? this.error,
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      message: message ?? this.message,
      duration: duration ?? this.duration,
    );
  }
}
