## 1.1.0

* **Changed**
  * **Flutter SDK Upgrade**: Upgraded package environment and constraints to require Flutter >=3.44.2 and Dart >=3.12.0 <4.0.0 (matching Flutter 3.44.2 release).
  * **iOS Target Bump**: Upgraded iOS deployment target to 15.0 to ensure compatibility with Swift Package Manager and modern iOS configurations under Flutter 3.44.2.
  * Added default Android platform setup in the example project.

## 1.0.0

* **Initial Release of the New Dio-based Custom Client**:
  * **ApiService**: Central API service class for executing HTTP requests (GET, POST, PUT, DELETE, PATCH) with full response parsing and error mapping.
  * **ApiConfig**: Global runtime configuration configuration support (base URL, global headers, timeouts, error callbacks).
  * **ApiException & ApiResponse**: Unified model structures for request errors, success wrappers, and status checks.
  * **DownloadHelper**: Dedicated utility supporting file download (including single/multiple images and videos) with real-time download progress callbacks.
  * **FormDataHelper**: Seamless utility to generate multipart requests, upload files, and mixed uploads.
  * **NetworkChecker**: Internet connection verification with automatic connection status subscription.
  * **RetryInterceptor**: Automatic connection retry wrapper featuring exponential backoff support.
  * **ApiLogger**: Beautifully formatted terminal and console logs for HTTP requests, responses, and errors.
