/// Global API Configuration Class
/// This class manages all API settings including base URL, headers, timeouts, and more.
class ApiConfig {
  /// Singleton instance
  static final ApiConfig _instance = ApiConfig._internal();
  factory ApiConfig() => _instance;
  ApiConfig._internal();

  /// Base URL for all API calls
  String _baseUrl = '';
  String get baseUrl => _baseUrl;

  /// Global headers applied to all requests
  Map<String, dynamic> _globalHeaders = {};
  Map<String, dynamic> get globalHeaders => _globalHeaders;

  /// Authentication token
  String? _token;
  String? get token => _token;

  /// Request timeout duration
  Duration _connectTimeout = const Duration(seconds: 30);
  Duration get connectTimeout => _connectTimeout;

  Duration _receiveTimeout = const Duration(seconds: 30);
  Duration get receiveTimeout => _receiveTimeout;

  Duration _sendTimeout = const Duration(seconds: 30);
  Duration get sendTimeout => _sendTimeout;

  /// Enable/disable console logs
  bool _enableLogs = true;
  bool get enableLogs => _enableLogs;

  /// Retry configuration
  bool _enableRetry = false;
  bool get enableRetry => _enableRetry;

  int _retryCount = 3;
  int get retryCount => _retryCount;

  Duration _retryDelay = const Duration(seconds: 2);
  Duration get retryDelay => _retryDelay;

  /// Exponential backoff for retry delays
  bool _exponentialBackoff = false;
  bool get exponentialBackoff => _exponentialBackoff;

  /// Global exception handler callback
  Function(dynamic exception)? _globalExceptionHandler;
  Function(dynamic exception)? get globalExceptionHandler =>
      _globalExceptionHandler;

  /// Callback for unauthorized responses (401)
  Function()? _onUnauthorized;
  Function()? get onUnauthorized => _onUnauthorized;

  /// Check internet before API call
  bool _checkInternetBeforeCall = true;
  bool get checkInternetBeforeCall => _checkInternetBeforeCall;

  /// Initialize configuration with required parameters
  void initialize({
    required String baseUrl,
    Map<String, dynamic>? headers,
    String? token,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool enableLogs = true,
    bool enableRetry = false,
    int retryCount = 3,
    Duration? retryDelay,
    bool exponentialBackoff = false,
    Function(dynamic exception)? globalExceptionHandler,
    Function()? onUnauthorized,
    bool checkInternetBeforeCall = true,
  }) {
    _baseUrl = baseUrl;
    _globalHeaders = headers ?? {};
    _token = token;
    _connectTimeout = connectTimeout ?? _connectTimeout;
    _receiveTimeout = receiveTimeout ?? _receiveTimeout;
    _sendTimeout = sendTimeout ?? _sendTimeout;
    _enableLogs = enableLogs;
    _enableRetry = enableRetry;
    _retryCount = retryCount;
    _retryDelay = retryDelay ?? _retryDelay;
    _exponentialBackoff = exponentialBackoff;
    _globalExceptionHandler = globalExceptionHandler;
    _onUnauthorized = onUnauthorized;
    _checkInternetBeforeCall = checkInternetBeforeCall;
  }

  /// Update base URL dynamically
  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
  }

  /// Update token dynamically (for authentication)
  void updateToken(String? newToken) {
    _token = newToken;
    if (newToken != null && newToken.isNotEmpty) {
      _globalHeaders['Authorization'] = 'Bearer $newToken';
    } else {
      _globalHeaders.remove('Authorization');
    }
  }

  /// Add or update a global header
  void addHeader(String key, dynamic value) {
    _globalHeaders[key] = value;
  }

  /// Remove a global header
  void removeHeader(String key) {
    _globalHeaders.remove(key);
  }

  /// Update global headers
  void updateHeaders(Map<String, dynamic> headers) {
    _globalHeaders.addAll(headers);
  }

  /// Clear all global headers
  void clearHeaders() {
    _globalHeaders.clear();
  }

  /// Update timeout settings
  void updateTimeouts({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    if (connectTimeout != null) _connectTimeout = connectTimeout;
    if (receiveTimeout != null) _receiveTimeout = receiveTimeout;
    if (sendTimeout != null) _sendTimeout = sendTimeout;
  }

  /// Update retry configuration
  void updateRetryConfig({
    bool? enableRetry,
    int? retryCount,
    Duration? retryDelay,
    bool? exponentialBackoff,
  }) {
    if (enableRetry != null) _enableRetry = enableRetry;
    if (retryCount != null) _retryCount = retryCount;
    if (retryDelay != null) _retryDelay = retryDelay;
    if (exponentialBackoff != null) _exponentialBackoff = exponentialBackoff;
  }

  /// Enable or disable logging
  void setLogging(bool enable) {
    _enableLogs = enable;
  }

  /// Set global exception handler
  void setGlobalExceptionHandler(Function(dynamic exception)? handler) {
    _globalExceptionHandler = handler;
  }

  /// Set unauthorized callback
  void setUnauthorizedCallback(Function()? callback) {
    _onUnauthorized = callback;
  }

  /// Reset configuration to defaults
  void reset() {
    _baseUrl = '';
    _globalHeaders = {};
    _token = null;
    _connectTimeout = const Duration(seconds: 30);
    _receiveTimeout = const Duration(seconds: 30);
    _sendTimeout = const Duration(seconds: 30);
    _enableLogs = true;
    _enableRetry = false;
    _retryCount = 3;
    _retryDelay = const Duration(seconds: 2);
    _exponentialBackoff = false;
    _globalExceptionHandler = null;
    _onUnauthorized = null;
    _checkInternetBeforeCall = true;
  }
}
