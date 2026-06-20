import 'package:dio/dio.dart';
import 'api_config.dart';
import 'logger.dart';

/// Retry Interceptor for automatic retry on failed requests
class RetryInterceptor extends Interceptor {
  final ApiConfig config;
  final ApiLogger logger;

  RetryInterceptor({required this.config, required this.logger});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if retry is enabled for this request
    final retryEnabled =
        err.requestOptions.extra['retry'] as bool? ?? config.enableRetry;

    if (!retryEnabled) {
      // Retry not enabled, pass error through
      return handler.next(err);
    }

    // Get retry count from request options or use global config
    final maxRetries =
        err.requestOptions.extra['retryCount'] as int? ?? config.retryCount;
    final currentRetry = err.requestOptions.extra['currentRetry'] as int? ?? 0;

    // Check if we should retry this error type
    if (!_shouldRetry(err) || currentRetry >= maxRetries) {
      logger.log(
        'Max retries reached or error not retryable. Giving up.',
        isError: true,
      );
      return handler.next(err);
    }

    // Calculate delay with exponential backoff if enabled
    final baseDelay =
        err.requestOptions.extra['retryDelay'] as Duration? ??
        config.retryDelay;
    final useExponentialBackoff =
        err.requestOptions.extra['exponentialBackoff'] as bool? ??
        config.exponentialBackoff;

    final delay = useExponentialBackoff
        ? _calculateExponentialDelay(baseDelay, currentRetry)
        : baseDelay;

    // Log retry attempt
    logger.log(
      '🔄 Retrying request (${currentRetry + 1}/$maxRetries) after ${delay.inMilliseconds}ms...',
    );

    // Wait before retrying
    await Future.delayed(delay);

    // Create new options with updated retry count
    final newOptions = err.requestOptions.copyWith();
    newOptions.extra['currentRetry'] = currentRetry + 1;

    try {
      // Retry the request
      final response = await Dio().fetch(newOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      // If retry also fails, pass it to error handler again
      return super.onError(e, handler);
    }
  }

  /// Determine if the error should trigger a retry
  bool _shouldRetry(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // Retry on timeout errors
        return true;

      case DioExceptionType.connectionError:
        // Retry on connection errors (including no internet)
        return true;

      case DioExceptionType.badResponse:
        // Retry on specific server errors (500, 502, 503, 504)
        final statusCode = error.response?.statusCode;
        return statusCode != null &&
            (statusCode == 500 ||
                statusCode == 502 ||
                statusCode == 503 ||
                statusCode == 504);

      case DioExceptionType.cancel:
        // Don't retry cancelled requests
        return false;

      case DioExceptionType.badCertificate:
        // Don't retry certificate errors
        return false;

      case DioExceptionType.unknown:
        // Check if it's a socket exception (network issue)
        if (error.error.toString().contains('SocketException')) {
          return true;
        }
        return false;
    }
  }

  /// Calculate delay with exponential backoff
  Duration _calculateExponentialDelay(Duration baseDelay, int retryCount) {
    // Formula: baseDelay * (2 ^ retryCount)
    // e.g., 2s, 4s, 8s, 16s...
    final multiplier = (1 << retryCount); // 2^retryCount
    final delayInMilliseconds = baseDelay.inMilliseconds * multiplier;

    // Cap maximum delay at 30 seconds to avoid extremely long waits
    const maxDelayMs = 30000;
    final cappedDelay = delayInMilliseconds > maxDelayMs
        ? maxDelayMs
        : delayInMilliseconds;

    return Duration(milliseconds: cappedDelay);
  }
}

/// Extension on RequestOptions to easily add retry configuration
extension RetryOptionsExtension on RequestOptions {
  /// Enable retry for this request
  RequestOptions withRetry({
    bool enabled = true,
    int? retryCount,
    Duration? retryDelay,
    bool? exponentialBackoff,
  }) {
    extra['retry'] = enabled;
    if (retryCount != null) extra['retryCount'] = retryCount;
    if (retryDelay != null) extra['retryDelay'] = retryDelay;
    if (exponentialBackoff != null) {
      extra['exponentialBackoff'] = exponentialBackoff;
    }
    return this;
  }
}
