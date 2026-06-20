import 'package:dio/dio.dart';
import 'download_helper.dart';
import 'api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'logger.dart';
import 'network_checker.dart';
import 'retry_interceptor.dart';

/// Central API Service Class
/// Handles all HTTP operations with comprehensive error handling and logging
class ApiService {
  /// Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  late ApiConfig _config;
  late ApiLogger _logger;
  late NetworkChecker _networkChecker;
  late DownloadHelper _downloadHelper;

  /// Initialize API service
  void initialize() {
    _config = ApiConfig();
    _logger = ApiLogger(enabled: _config.enableLogs);
    _networkChecker = NetworkChecker();

    // Initialize Dio
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: _config.connectTimeout,
        receiveTimeout: _config.receiveTimeout,
        sendTimeout: _config.sendTimeout,
        headers: _config.globalHeaders,
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(RetryInterceptor(config: _config, logger: _logger));

    // Initialize download helper
    _downloadHelper = DownloadHelper(
      dio: _dio,
      config: _config,
      logger: _logger,
    );

    // Initialize network checker
    _networkChecker.initialize();
  }

  // /// Update Dio instance when config changes
  // void _updateDio() {
  //   _dio.options.baseUrl = _config.baseUrl;
  //   _dio.options.connectTimeout = _config.connectTimeout;
  //   _dio.options.receiveTimeout = _config.receiveTimeout;
  //   _dio.options.sendTimeout = _config.sendTimeout;
  //   _dio.options.headers = _config.globalHeaders;
  //   _logger.enabled = _config.enableLogs;
  // }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool overrideGlobalError = true,
    bool? retry,
    bool checkInternet = true,
    Duration? timeout,
    T Function(dynamic)? parser,
  }) async {
    return _executeRequest<T>(
      method: 'GET',
      endpoint: endpoint,
      queryParameters: queryParameters,
      headers: headers,
      overrideGlobalError: overrideGlobalError,
      retry: retry,
      checkInternet: checkInternet,
      timeout: timeout,
      parser: parser,
    );
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool overrideGlobalError = false,
    bool? retry,
    bool checkInternet = true,
    Duration? timeout,
    T Function(dynamic)? parser,
  }) async {
    return _executeRequest<T>(
      method: 'POST',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      overrideGlobalError: overrideGlobalError,
      retry: retry,
      checkInternet: checkInternet,
      timeout: timeout,
      parser: parser,
    );
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool overrideGlobalError = false,
    bool? retry,
    bool checkInternet = true,
    Duration? timeout,
    T Function(dynamic)? parser,
  }) async {
    return _executeRequest<T>(
      method: 'PUT',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      overrideGlobalError: overrideGlobalError,
      retry: retry,
      checkInternet: checkInternet,
      timeout: timeout,
      parser: parser,
    );
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool overrideGlobalError = false,
    bool? retry,
    bool checkInternet = true,
    Duration? timeout,
    T Function(dynamic)? parser,
  }) async {
    return _executeRequest<T>(
      method: 'DELETE',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      overrideGlobalError: overrideGlobalError,
      retry: retry,
      checkInternet: checkInternet,
      timeout: timeout,
      parser: parser,
    );
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool overrideGlobalError = false,
    bool? retry,
    bool checkInternet = true,
    Duration? timeout,
    T Function(dynamic)? parser,
  }) async {
    return _executeRequest<T>(
      method: 'PATCH',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      overrideGlobalError: overrideGlobalError,
      retry: retry,
      checkInternet: checkInternet,
      timeout: timeout,
      parser: parser,
    );
  }

  /// Execute HTTP request with comprehensive error handling
  Future<ApiResponse<T>> _executeRequest<T>({
    required String method,
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool overrideGlobalError = false,
    bool? retry,
    bool checkInternet = true,
    Duration? timeout,
    T Function(dynamic)? parser,
  }) async {
    final startTime = DateTime.now();

    try {
      // Check internet connection if enabled
      if (checkInternet && _config.checkInternetBeforeCall) {
        final hasInternet = await _networkChecker.checkConnectivity();
        if (!hasInternet) {
          final exception = ApiException.noInternet();
          _handleGlobalException(exception, overrideGlobalError);
          return ApiResponse.error(error: exception);
        }
      }

      // Merge headers
      final mergedHeaders = {
        ..._config.globalHeaders,
        ...?headers,
      };

      // Prepare options
      final options = Options(
        method: method,
        headers: mergedHeaders,
        receiveTimeout: timeout ?? _config.receiveTimeout,
        sendTimeout: timeout ?? _config.sendTimeout,
      );

      // Set retry configuration in request options
      options.extra = {
        'retry': retry ?? _config.enableRetry,
        'retryCount': _config.retryCount,
        'retryDelay': _config.retryDelay,
        'exponentialBackoff': _config.exponentialBackoff,
        'currentRetry': 0,
      };

      // Log request
      final requestOptions = RequestOptions(
        path: endpoint,
        method: method,
        baseUrl: _config.baseUrl,
        data: data,
        queryParameters: queryParameters,
        headers: mergedHeaders,
      );
      _logger.logRequest(requestOptions, startTime: startTime);

      // Execute request
      final response = await _dio.request(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log response
      _logger.logResponse(response, startTime: startTime, endTime: endTime);

      // Parse response
      T? parsedData;
      if (parser != null && response.data != null) {
        try {
          parsedData = parser(response.data);
        } catch (e) {
          _logger.log('Failed to parse response: $e', isError: true);
        }
      }

      return ApiResponse.success(
        data: parsedData,
        raw: response.data,
        statusCode: response.statusCode,
        headers: response.headers.map,
        duration: duration,
      );
    } on DioException catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log error
      _logger.logError(e, startTime: startTime, endTime: endTime);

      // Create ApiException
      final exception = ApiException.fromDioException(e);

      // Handle unauthorized
      if (exception.type == ApiExceptionType.unauthorized) {
        _config.onUnauthorized?.call();
      }

      // Call global exception handler
      _handleGlobalException(exception, overrideGlobalError);

      return ApiResponse.error(
        error: exception,
        raw: e.response?.data,
        statusCode: e.response?.statusCode,
        headers: e.response?.headers.map,
        duration: duration,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _logger.log('Unexpected error: $e', isError: true);

      final exception = ApiException.custom(
        message: 'Unexpected error: ${e.toString()}',
        type: ApiExceptionType.unknown,
        originalError: e,
      );

      _handleGlobalException(exception, overrideGlobalError);

      return ApiResponse.error(error: exception, duration: duration);
    }
  }

  /// Execute multiple requests in parallel
  Future<List<ApiResponse>> multiRequest(
    List<Future<ApiResponse>> requests,
  ) async {
    _logger.log('🔄 Executing ${requests.length} parallel requests...');

    try {
      final results = await Future.wait(requests);

      final successCount = results.where((r) => r.isSuccess).length;
      _logger.log(
        '✅ Completed $successCount/${requests.length} requests successfully',
      );

      return results;
    } catch (e) {
      _logger.log('Error in parallel requests: $e', isError: true);
      rethrow;
    }
  }

  /// Download file
  Future<DownloadResult> downloadFile({
    required String url,
    String? savePath,
    String? filename,
    Map<String, dynamic>? headers,
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _downloadHelper.downloadFile(
      url: url,
      savePath: savePath,
      filename: filename,
      headers: headers,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  /// Download image
  Future<DownloadResult> downloadImage({
    required String url,
    String? savePath,
    String? filename,
    Map<String, dynamic>? headers,
    Function(int received, int total)? onProgress,
  }) {
    return _downloadHelper.downloadImage(
      url: url,
      savePath: savePath,
      filename: filename,
      headers: headers,
      onProgress: onProgress,
    );
  }

  /// Download video
  Future<DownloadResult> downloadVideo({
    required String url,
    String? savePath,
    String? filename,
    Map<String, dynamic>? headers,
    Function(int received, int total)? onProgress,
  }) {
    return _downloadHelper.downloadVideo(
      url: url,
      savePath: savePath,
      filename: filename,
      headers: headers,
      onProgress: onProgress,
    );
  }

  /// Download multiple files
  Future<List<DownloadResult>> downloadMultiple({
    required List<String> urls,
    String? saveDirectory,
    Map<String, dynamic>? headers,
    Function(String url, int received, int total)? onProgress,
  }) {
    return _downloadHelper.downloadMultiple(
      urls: urls,
      saveDirectory: saveDirectory,
      headers: headers,
      onProgress: onProgress,
    );
  }

  /// Cancel download
  void cancelDownload(String url) {
    _downloadHelper.cancelDownload(url);
  }

  /// Cancel all downloads
  void cancelAllDownloads() {
    _downloadHelper.cancelAllDownloads();
  }

  /// Handle global exception
  void _handleGlobalException(ApiException exception, bool override) {
    if (!override && _config.globalExceptionHandler != null) {
      _config.globalExceptionHandler!(exception);
    }
  }

  /// Get Dio instance (for advanced usage)
  Dio get dio => _dio;

  /// Get config instance
  ApiConfig get config => _config;

  /// Get logger instance
  ApiLogger get logger => _logger;

  /// Get network checker instance
  NetworkChecker get networkChecker => _networkChecker;

  /// Get download helper instance
  DownloadHelper get downloadHelper => _downloadHelper;

  /// Dispose resources
  void dispose() {
    _networkChecker.dispose();
    _downloadHelper.cancelAllDownloads();
  }
}
