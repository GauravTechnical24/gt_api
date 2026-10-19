import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;

/// API Logger for beautiful console output
/// Provides detailed logging for requests and responses
class ApiLogger {
  /// Check if logging is enabled
  bool enabled;

  /// Enable/disable ANSI colors
  bool useColors;

  ApiLogger({this.enabled = true, bool? useColors})
    : useColors = useColors ?? _shouldUseColors();

  /// Auto-detect if ANSI colors should be used
  static bool _shouldUseColors() {
    try {
      // Disable colors in Flutter debug mode to avoid ANSI escape sequence issues in IDE consoles (e.g., VSCode)
      if (kDebugMode) return false;
      // Disable on Windows by default (unless explicitly enabled)
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        return false;
      }
      // Enable colors on Linux and macOS (terminal)
      return true;
    } catch (e) {
      // If Platform check fails, disable colors
      return false;
    }
  }

  /// ANSI color codes (only used if useColors is true)
  String get _reset => useColors ? '\x1B[0m' : '';
  String get _cyan => useColors ? '\x1B[36m' : '';
  String get _green => useColors ? '\x1B[32m' : '';
  String get _yellow => useColors ? '\x1B[33m' : '';
  String get _red => useColors ? '\x1B[31m' : '';
  String get _blue => useColors ? '\x1B[34m' : '';
  String get _magenta => useColors ? '\x1B[35m' : '';
  String get _bold => useColors ? '\x1B[1m' : '';

  /// Output a line (uses print() in debug mode to avoid "flutter: " prefix)
  void _outputLine(String line) {
    if (kDebugMode) {
      debugPrint(
        line,
      ); // Use print() to skip "flutter: " prefix in Flutter debug console
    } else {
      debugPrint(line); // Or debugPrint(line) if you prefer prefix in non-debug
    }
  }

  /// Log request details
  void logRequest(RequestOptions options, {DateTime? startTime}) {
    if (!enabled) return;
    final uri = options.uri;
    final method = options.method.toUpperCase();
    final headers = options.headers;
    final data = options.data;
    final queryParameters = options.queryParameters;

    _outputLine('\n$_cyan┌${'─' * 58}┐$_reset');
    _outputLine(
      '$_cyan│$_bold$_cyan📤 API REQUEST$_reset $_bold$_yellow[${_formatDateTime(startTime ?? DateTime.now())}]$_reset$_cyan│$_reset',
    );
    _outputLine('$_cyan└${'─' * 58}┘$_reset');

    // Method and URL
    _outputLine('$_bold${_blue}Method:$_reset $method');
    _outputLine('$_bold${_magenta}URL:$_reset $uri');

    // Headers (with token display - full for debugging, but masked in production if needed)
    if (headers.isNotEmpty) {
      _outputLine('\n$_yellow📋 Headers:$_reset');
      headers.forEach((key, value) {
        final displayValue = _maskSensitiveHeader(key, value.toString());
        _outputLine('  $_bold$key:$_reset $displayValue');
      });
    }

    // Query Parameters
    if (queryParameters.isNotEmpty) {
      _outputLine('\n$_yellow🔍 Query Parameters:$_reset');
      queryParameters.forEach((key, value) {
        _outputLine('  $_bold$key:$_reset $value');
      });
    }

    // Request Body
    if (data != null) {
      _outputLine('\n$_yellow📦 Request Body:$_reset');
      if (data is FormData) {
        _logFormData(data);
      } else if (data is Map || data is List) {
        try {
          final prettyJson = JsonEncoder.withIndent('  ').convert(data);
          _outputPrettyJson(prettyJson);
        } catch (e) {
          _outputLine(data.toString());
        }
      } else {
        _outputLine(data.toString());
      }
    }

    _outputLine('$_cyan└${'─' * 60}┘$_reset');
  }

  /// Log response details
  void logResponse(
    Response response, {
    DateTime? startTime,
    DateTime? endTime,
  }) {
    if (!enabled) return;
    final statusCode = response.statusCode;
    final data = response.data;
    final headers = response.headers.map;
    final duration = endTime != null && startTime != null
        ? endTime.difference(startTime)
        : null;
    final method = response.requestOptions.method.toUpperCase(); // API Type

    _outputLine('\n$_green┌${'─' * 58}┐$_reset');
    _outputLine(
      '$_green│$_bold$_green📥 API RESPONSE$_reset $_bold$_yellow[${_formatDateTime(endTime ?? DateTime.now())} | ${duration?.inMilliseconds ?? 0}ms]$_reset$_green│$_reset',
    );
    _outputLine('$_green└${'─' * 58}┘$_reset');

    // Status and API Type
    final statusEmoji = _getStatusEmoji(statusCode);
    _outputLine(
      '$_bold${_getStatusColor(statusCode)}Status Code:$_reset $statusCode $statusEmoji',
    );
    _outputLine(
      '$_bold${_blue}API Type (Method):$_reset $method',
    ); // Display API Type

    // URL
    _outputLine('$_bold${_magenta}URL:$_reset ${response.requestOptions.uri}');

    // Response Headers (optional - can be commented out if too verbose)
    if (headers.isNotEmpty && _shouldLogHeaders()) {
      _outputLine('\n$_yellow📋 Response Headers:$_reset');
      headers.forEach((key, values) {
        final displayValue = _maskSensitiveHeader(key, values.join(', '));
        _outputLine('  $_bold$key:$_reset $displayValue');
      });
    }

    // Response Body (full print, no truncation)
    if (data != null) {
      _outputLine('\n$_yellow📦 Response Body:$_reset');
      if (data is Map || data is List) {
        try {
          final prettyJson = JsonEncoder.withIndent('  ').convert(data);
          _outputPrettyJson(prettyJson); // Full output
        } catch (e) {
          _outputLine(data.toString());
        }
      } else if (data is String) {
        _outputLine(data); // Full string, no truncation
      } else {
        _outputLine(data.toString());
      }
    }

    _outputLine('$_green└${'─' * 60}┘$_reset\n');
  }

  /// Helper to output pretty JSON, splitting lines for debugPrint
  void _outputPrettyJson(String prettyJson) {
    final lines = prettyJson.split('\n');
    for (final line in lines) {
      _outputLine(line);
    }
  }

  /// Log error details
  void logError(DioException error, {DateTime? startTime, DateTime? endTime}) {
    if (!enabled) return;
    final response = error.response;
    final statusCode = response?.statusCode;
    final duration = endTime != null && startTime != null
        ? endTime.difference(startTime)
        : null;
    final method = error.requestOptions.method.toUpperCase(); // API Type

    _outputLine('\n$_red┌${'─' * 58}┐$_reset');
    _outputLine(
      '$_red│$_bold$_red❌ API ERROR$_reset $_bold$_yellow[${_formatDateTime(endTime ?? DateTime.now())} | ${duration?.inMilliseconds ?? 0}ms]$_reset$_red│$_reset',
    );
    _outputLine('$_red└${'─' * 58}┘$_reset');

    // Error Type and API Type
    _outputLine('$_bold${_red}Error Type:$_reset ${error.type}');
    _outputLine('$_bold${_blue}API Type (Method):$_reset $method');

    // URL
    _outputLine('$_bold${_magenta}URL:$_reset ${error.requestOptions.uri}');

    // Status Code
    if (statusCode != null) {
      _outputLine('$_bold${_red}Status Code:$_reset $statusCode');
    }

    // Error Message
    if (error.message != null) {
      _outputLine('$_red💬 Message:$_reset ${error.message}');
    }

    // Response Data (full print, no truncation)
    if (response?.data != null) {
      _outputLine('\n$_yellow📦 Error Response:$_reset');
      final data = response!.data;
      if (data is Map || data is List) {
        try {
          final prettyJson = JsonEncoder.withIndent('  ').convert(data);
          _outputPrettyJson(prettyJson); // Full output
        } catch (e) {
          _outputLine(data.toString());
        }
      } else {
        _outputLine(data.toString());
      }
    }

    _outputLine('$_red└${'─' * 60}┘$_reset\n');
  }

  /// Log FormData details
  void _logFormData(FormData formData) {
    _outputLine('\n$_yellow📝 Form Fields:$_reset');
    for (var field in formData.fields) {
      _outputLine('  $_bold${field.key}:$_reset ${field.value}');
    }
    if (formData.files.isNotEmpty) {
      _outputLine('\n$_yellow📎 Files:$_reset');
      for (var file in formData.files) {
        final multipartFile = file.value;
        final sizeInKB = (multipartFile.length).toStringAsFixed(2);
        _outputLine(
          '  $_bold${file.key}:$_reset ${multipartFile.filename ?? 'unnamed'} ($sizeInKB KB)',
        );
      }
    }
  }

  /// Get color based on status code
  String _getStatusColor(int? statusCode) {
    if (!useColors) return '';
    if (statusCode == null) return _reset;
    if (statusCode >= 200 && statusCode < 300) return _green;
    if (statusCode >= 300 && statusCode < 400) return _yellow;
    if (statusCode >= 400 && statusCode < 500) return _red;
    if (statusCode >= 500) return _red;
    return _reset;
  }

  /// Get emoji based on status code
  String _getStatusEmoji(int? statusCode) {
    if (statusCode == null) return '❓';
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 300 && statusCode < 400) return '🔄';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    if (statusCode >= 500) return '❌';
    return '❓';
  }

  /// Format DateTime
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}.'
        '${dateTime.millisecond.toString().padLeft(3, '0')}';
  }

  /// Check if headers should be logged (can be disabled to reduce verbosity)
  bool _shouldLogHeaders() {
    // Set to false to hide response headers and reduce log size
    return false;
  }

  /// Mask sensitive headers like tokens (customize as needed; currently shows full for display)
  String _maskSensitiveHeader(String key, String value) {
    // Example: Mask Authorization token but show 'Bearer '
    if (key.toLowerCase() == 'authorization') {
      return value.replaceAll(RegExp(r'Bearer\s+(.+)'), 'Bearer [TOKEN]');
    }
    return value; // Show full for other headers
  }

  /// Log download progress
  void logDownloadProgress({
    required String url,
    required int received,
    required int total,
  }) {
    if (!enabled) return;
    final percentage = (received / total * 100).toStringAsFixed(1);
    final receivedMB = (received / (1024 * 1024)).toStringAsFixed(2);
    final totalMB = (total / (1024 * 1024)).toStringAsFixed(2);
    _outputLine('$_cyan📥 Downloading:$_reset $url');
    _outputLine(
      '$_yellow Progress:$_reset $percentage% ($receivedMB MB / $totalMB MB)',
    );
  }

  /// Log custom message
  void log(String message, {bool isError = false}) {
    if (!enabled) return;
    if (isError) {
      _outputLine('$_red❌ $message$_reset');
    } else {
      _outputLine('$_cyan📝 $message$_reset');
    }
  }

  /// Simple log without formatting (for plain text)
  void logSimple(String message) {
    if (!enabled) return;
    _outputLine(message);
  }

  /// Log with custom prefix
  void logWithPrefix(String prefix, String message, {bool isError = false}) {
    if (!enabled) return;
    final color = isError ? _red : _cyan;
    _outputLine('$color$prefix$_reset $message');
  }
}
