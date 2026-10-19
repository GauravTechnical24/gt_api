/// A robust, elegant, and production-ready HTTP/REST API client wrapper for Flutter and Dart.
///
/// Exports core components including [ApiService], [ApiConfig], [ApiException],
/// [ApiResponse], [ApiLogger], [NetworkChecker], [RetryInterceptor],
/// [FormDataHelper], and [DownloadHelper].
library;

// Core API Service exports
export 'api_service/api_service.dart';
export 'api_service/api_config.dart';
export 'api_service/api_exception.dart';
export 'api_service/api_response.dart';
export 'api_service/logger.dart';
export 'api_service/network_checker.dart';
export 'api_service/retry_interceptor.dart';

// Helpers exports
export 'api_service/form_data_helper.dart';
export 'api_service/download_helper.dart';

// External dependencies (re-export for convenience)
export 'package:dio/dio.dart' show FormData, MultipartFile, CancelToken;
