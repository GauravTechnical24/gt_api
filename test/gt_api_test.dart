import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_api/gt_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiConfig Tests', () {
    late ApiConfig config;

    setUp(() {
      config = ApiConfig();
      config.reset();
    });

    test('default configuration values', () {
      expect(config.baseUrl, '');
      expect(config.globalHeaders, isEmpty);
      expect(config.token, isNull);
      expect(config.connectTimeout, const Duration(seconds: 30));
      expect(config.receiveTimeout, const Duration(seconds: 30));
      expect(config.sendTimeout, const Duration(seconds: 30));
      expect(config.enableLogs, isTrue);
      expect(config.enableRetry, isFalse);
      expect(config.retryCount, 3);
      expect(config.retryDelay, const Duration(seconds: 2));
      expect(config.exponentialBackoff, isFalse);
      expect(config.checkInternetBeforeCall, isTrue);
      expect(config.globalExceptionHandler, isNull);
      expect(config.onUnauthorized, isNull);
    });

    test('initializes with custom parameters', () {
      bool unauthorizedCalled = false;
      dynamic capturedException;

      config.initialize(
        baseUrl: 'https://api.example.com',
        headers: {'X-Custom': 'Value'},
        token: 'test_token',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 20),
        enableLogs: false,
        enableRetry: true,
        retryCount: 5,
        retryDelay: const Duration(seconds: 1),
        exponentialBackoff: true,
        checkInternetBeforeCall: false,
        globalExceptionHandler: (e) => capturedException = e,
        onUnauthorized: () => unauthorizedCalled = true,
      );

      expect(config.baseUrl, 'https://api.example.com');
      expect(config.globalHeaders['X-Custom'], 'Value');
      expect(config.token, 'test_token');
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(seconds: 15));
      expect(config.sendTimeout, const Duration(seconds: 20));
      expect(config.enableLogs, isFalse);
      expect(config.enableRetry, isTrue);
      expect(config.retryCount, 5);
      expect(config.retryDelay, const Duration(seconds: 1));
      expect(config.exponentialBackoff, isTrue);
      expect(config.checkInternetBeforeCall, isFalse);

      config.onUnauthorized?.call();
      expect(unauthorizedCalled, isTrue);

      config.globalExceptionHandler?.call('err');
      expect(capturedException, 'err');
    });

    test('updateBaseUrl updates base URL', () {
      config.updateBaseUrl('https://new.api.com');
      expect(config.baseUrl, 'https://new.api.com');
    });

    test('updateToken sets and removes authorization header', () {
      config.updateToken('jwt_123');
      expect(config.token, 'jwt_123');
      expect(config.globalHeaders['Authorization'], 'Bearer jwt_123');

      config.updateToken(null);
      expect(config.token, isNull);
      expect(config.globalHeaders.containsKey('Authorization'), isFalse);

      config.updateToken('');
      expect(config.token, '');
      expect(config.globalHeaders.containsKey('Authorization'), isFalse);
    });

    test('headers manipulation (add, remove, update, clear)', () {
      config.addHeader('Accept', 'application/json');
      expect(config.globalHeaders['Accept'], 'application/json');

      config.updateHeaders({'Cache': 'none', 'Version': '1.0'});
      expect(config.globalHeaders.length, 3);

      config.removeHeader('Accept');
      expect(config.globalHeaders.containsKey('Accept'), isFalse);

      config.clearHeaders();
      expect(config.globalHeaders, isEmpty);
    });

    test('updateTimeouts updates individual timeouts', () {
      config.updateTimeouts(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 9),
      );
      expect(config.connectTimeout, const Duration(seconds: 5));
      expect(config.receiveTimeout, const Duration(seconds: 8));
      expect(config.sendTimeout, const Duration(seconds: 9));
    });

    test('updateRetryConfig and setLogging', () {
      config.updateRetryConfig(
        enableRetry: true,
        retryCount: 4,
        retryDelay: const Duration(seconds: 3),
        exponentialBackoff: true,
      );
      expect(config.enableRetry, isTrue);
      expect(config.retryCount, 4);
      expect(config.retryDelay, const Duration(seconds: 3));
      expect(config.exponentialBackoff, isTrue);

      config.setLogging(false);
      expect(config.enableLogs, isFalse);

      config.setGlobalExceptionHandler((e) {});
      expect(config.globalExceptionHandler, isNotNull);

      config.setUnauthorizedCallback(() {});
      expect(config.onUnauthorized, isNotNull);
    });
  });

  group('ApiException Tests', () {
    test('fromDioException handles connectionTimeout & sendTimeout', () {
      final dioErr1 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final ex1 = ApiException.fromDioException(dioErr1);
      expect(ex1.type, ApiExceptionType.timeout);
      expect(ex1.isNetworkError, isTrue);

      final dioErr2 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );
      final ex2 = ApiException.fromDioException(dioErr2);
      expect(ex2.type, ApiExceptionType.timeout);
    });

    test('fromDioException handles receiveTimeout & transformTimeout', () {
      final dioErr1 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.receiveTimeout,
      );
      final ex1 = ApiException.fromDioException(dioErr1);
      expect(ex1.type, ApiExceptionType.receiveTimeout);

      final dioErr2 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.transformTimeout,
      );
      final ex2 = ApiException.fromDioException(dioErr2);
      expect(ex2.type, ApiExceptionType.timeout);
    });

    test('fromDioException handles cancel and badCertificate', () {
      final dioErr1 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.cancel,
      );
      final ex1 = ApiException.fromDioException(dioErr1);
      expect(ex1.type, ApiExceptionType.cancel);

      final dioErr2 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badCertificate,
      );
      final ex2 = ApiException.fromDioException(dioErr2);
      expect(ex2.type, ApiExceptionType.badCertificate);
    });

    test('fromDioException handles connectionError variants', () {
      final dioErr1 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
        message: 'SocketException: OS error',
      );
      final ex1 = ApiException.fromDioException(dioErr1);
      expect(ex1.type, ApiExceptionType.noInternet);

      final dioErr2 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
        message: 'CERTIFICATE_VERIFY_FAILED',
      );
      final ex2 = ApiException.fromDioException(dioErr2);
      expect(ex2.type, ApiExceptionType.badCertificate);

      final dioErr3 = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
        message: 'Network unreachable',
      );
      final ex3 = ApiException.fromDioException(dioErr3);
      expect(ex3.type, ApiExceptionType.socketException);
    });

    test('fromDioException handles badResponse status codes', () {
      final cases = [
        (400, ApiExceptionType.badRequest),
        (401, ApiExceptionType.unauthorized),
        (403, ApiExceptionType.forbidden),
        (404, ApiExceptionType.notFound),
        (500, ApiExceptionType.internalServerError),
        (502, ApiExceptionType.internalServerError),
        (503, ApiExceptionType.internalServerError),
        (418, ApiExceptionType.unknown),
      ];

      for (final (status, expectedType) in cases) {
        final dioErr = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: status,
            data: {'message': 'Custom error message'},
          ),
        );
        final ex = ApiException.fromDioException(dioErr);
        expect(ex.type, expectedType);
        expect(ex.statusCode, status);
        expect(ex.message, 'Custom error message');
      }
    });

    test('fromDioException parses nested error message', () {
      final dioErr = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {
            'error': {'message': 'Validation failed'},
          },
        ),
      );
      final ex = ApiException.fromDioException(dioErr);
      expect(ex.message, 'Validation failed');
    });

    test(
      'helper flags (isNetworkError, isAuthError, isClientError, isServerError)',
      () {
        final clientEx = ApiException.custom(
          message: 'Bad',
          statusCode: 400,
          type: ApiExceptionType.badRequest,
        );
        expect(clientEx.isClientError, isTrue);
        expect(clientEx.isServerError, isFalse);

        final authEx = ApiException.custom(
          message: 'Auth',
          statusCode: 401,
          type: ApiExceptionType.unauthorized,
        );
        expect(authEx.isAuthError, isTrue);

        final serverEx = ApiException.custom(
          message: 'Server',
          statusCode: 500,
          type: ApiExceptionType.internalServerError,
        );
        expect(serverEx.isServerError, isTrue);

        final noInternetEx = ApiException.noInternet();
        expect(noInternetEx.isNetworkError, isTrue);
        expect(noInternetEx.type, ApiExceptionType.noInternet);
      },
    );

    test('toJson, toString and toDetailedString', () {
      final ex = ApiException.custom(
        message: 'Failure',
        statusCode: 404,
        errorData: {'field': 'id'},
        originalError: 'not found',
      );

      final json = ex.toJson();
      expect(json['message'], 'Failure');
      expect(json['statusCode'], 404);
      expect(json['errorData']['field'], 'id');

      expect(ex.toString(), contains('Failure'));
      expect(ex.toDetailedString(), contains('ApiException Details:'));
    });
  });

  group('ApiResponse Tests', () {
    test('success response properties and dataOrThrow', () {
      final response = ApiResponse<String>.success(
        data: 'Hello World',
        raw: {'msg': 'Hello World'},
        statusCode: 200,
        headers: {
          'content-type': ['application/json'],
        },
        duration: const Duration(milliseconds: 150),
      );

      expect(response.isSuccess, isTrue);
      expect(response.isError, isFalse);
      expect(response.isStatusSuccess, isTrue);
      expect(response.dataOrThrow, 'Hello World');
      expect(response.dataOrDefault('Default'), 'Hello World');
      expect(response.dataOrNull, 'Hello World');
      expect(response.duration?.inMilliseconds, 150);
    });

    test('error response throws on dataOrThrow', () {
      final ex = ApiException.custom(
        message: 'Failed',
        statusCode: 500,
        type: ApiExceptionType.internalServerError,
      );
      final response = ApiResponse<String>.error(error: ex, statusCode: 500);

      expect(response.isSuccess, isFalse);
      expect(response.isError, isTrue);
      expect(response.isStatusSuccess, isFalse);
      expect(() => response.dataOrThrow, throwsA(isA<ApiException>()));
      expect(response.dataOrDefault('Fallback'), 'Fallback');
      expect(response.dataOrNull, isNull);
    });

    test('onSuccess and onError callbacks', () {
      final successResp = ApiResponse<int>.success(data: 42);
      int capturedSuccess = 0;
      successResp.onSuccess((data) => capturedSuccess = data ?? 0);
      expect(capturedSuccess, 42);

      final errorResp = ApiResponse<int>.error(
        error: ApiException.noInternet(),
      );
      ApiException? capturedError;
      errorResp.onError((err) => capturedError = err);
      expect(capturedError?.type, ApiExceptionType.noInternet);
    });

    test('transform and map operations', () {
      final original = ApiResponse<int>.success(data: 10, statusCode: 200);
      final transformed = original.transform<String>((val) => 'Value: $val');
      expect(transformed.data, 'Value: 10');
      expect(transformed.isSuccess, isTrue);

      final mapped = original.map<String>((val) => 'Mapped: $val');
      expect(mapped.data, 'Mapped: 10');

      final failedResp = ApiResponse<int>.error(
        error: ApiException.custom(message: 'Error'),
      );
      final mappedError = failedResp.map<String>((val) => 'Never');
      expect(mappedError.isError, isTrue);
    });

    test('toJson, toString and copyWith', () {
      final resp = ApiResponse<String>.success(
        data: 'Data',
        message: 'OK',
        statusCode: 200,
      );

      final json = resp.toJson();
      expect(json['status'], contains('success'));
      expect(json['statusCode'], 200);

      expect(resp.toString(), contains('ApiResponse.success'));
      expect(resp.toDetailedString(), contains('ApiResponse:'));

      final copy = resp.copyWith(statusCode: 201);
      expect(copy.statusCode, 201);
      expect(copy.data, 'Data');
    });
  });

  group('RetryInterceptor Tests', () {
    test('RequestOptions withRetry extension', () {
      final options = RequestOptions(path: '/test');
      options.withRetry(
        enabled: true,
        retryCount: 4,
        retryDelay: const Duration(seconds: 3),
        exponentialBackoff: true,
      );

      expect(options.extra['retry'], isTrue);
      expect(options.extra['retryCount'], 4);
      expect(options.extra['retryDelay'], const Duration(seconds: 3));
      expect(options.extra['exponentialBackoff'], isTrue);
    });
  });

  group('FormDataHelper & FileUploadItem Tests', () {
    test('FileUploadItem type detection', () {
      final imgItem = FileUploadItem(
        file: File('photo.jpg'),
        fieldName: 'avatar',
      );
      expect(imgItem.isImage, isTrue);
      expect(imgItem.isVideo, isFalse);
      expect(imgItem.isDocument, isFalse);
      expect(imgItem.extension, 'jpg');

      final videoItem = FileUploadItem(
        file: File('movie.mp4'),
        fieldName: 'clip',
      );
      expect(videoItem.isVideo, isTrue);
      expect(videoItem.isImage, isFalse);

      final docItem = FileUploadItem(file: File('notes.pdf'), fieldName: 'doc');
      expect(docItem.isDocument, isTrue);
    });

    test('validateFile returns false for non-existent file', () {
      final nonExistent = File('/path/that/does/not/exist.txt');
      expect(FormDataHelper.validateFile(file: nonExistent), isFalse);
    });
  });

  group('DownloadResult Tests', () {
    test('formattedFileSize formats properly', () {
      final result1 = DownloadResult(
        success: true,
        filePath: '/tmp/test.txt',
        fileSize: 500,
        duration: const Duration(milliseconds: 50),
      );
      expect(result1.formattedFileSize, '500 B');
      expect(result1.toString(), contains('DownloadResult.success'));

      final result2 = DownloadResult(success: true, fileSize: 2048);
      expect(result2.formattedFileSize, '2.00 KB');

      final result3 = DownloadResult(success: true, fileSize: 5 * 1024 * 1024);
      expect(result3.formattedFileSize, '5.00 MB');

      final errorResult = DownloadResult(
        success: false,
        error: 'Network error',
      );
      expect(errorResult.toString(), contains('DownloadResult.error'));
      expect(errorResult.formattedFileSize, isNull);
    });
  });

  group('NetworkChecker Tests', () {
    test('NetworkChecker singleton and initial state', () {
      final checker = NetworkChecker();
      expect(checker.isConnected, isTrue);
      checker.reset();
      expect(checker.isConnected, isTrue);
    });
  });

  group('ApiLogger Tests', () {
    test('ApiLogger logs without throwing', () {
      final logger = ApiLogger(enabled: true, useColors: false);
      expect(() => logger.log('Test message'), returnsNormally);
      expect(() => logger.log('Error message', isError: true), returnsNormally);
      expect(() => logger.logSimple('Simple message'), returnsNormally);
      expect(
        () => logger.logWithPrefix('[PREFIX]', 'Prefixed message'),
        returnsNormally,
      );
      expect(
        () => logger.logDownloadProgress(
          url: 'https://example.com/file',
          received: 500,
          total: 1000,
        ),
        returnsNormally,
      );

      final disabledLogger = ApiLogger(enabled: false);
      expect(() => disabledLogger.log('Silent'), returnsNormally);
    });
  });

  group('ApiService Integration Tests', () {
    setUp(() {
      ApiConfig().reset();
    });

    test('ApiService initializes with ApiConfig and Dio', () {
      final config = ApiConfig();
      config.initialize(
        baseUrl: 'https://jsonplaceholder.typicode.com',
        enableLogs: false,
      );

      final service = ApiService();
      service.initialize();

      expect(service.config.baseUrl, 'https://jsonplaceholder.typicode.com');
      expect(
        service.dio.options.baseUrl,
        'https://jsonplaceholder.typicode.com',
      );
      expect(service.logger, isNotNull);
      expect(service.networkChecker, isNotNull);
      expect(service.downloadHelper, isNotNull);
    });
  });
}
