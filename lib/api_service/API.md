# API Utility Package 🚀

A comprehensive, production-ready Flutter API utility package with Dio, featuring global configuration, exception handling, auto-retry, file uploads/downloads, and beautiful console logging.

## 📁 Folder Structure

```
lib/
├── src/
│   ├── core/
│   │   ├── api_config.dart          # Global configuration management
│   │   ├── api_service.dart         # Core API service with HTTP methods
│   │   ├── api_exception.dart       # Custom exception handling
│   │   ├── api_response.dart        # Generic response wrapper
│   │   ├── logger.dart              # Beautiful console logger
│   │   ├── network_checker.dart     # Internet connectivity checker
│   │   └── retry_interceptor.dart   # Auto-retry logic
│   ├── helpers/
│   │   ├── form_data_helper.dart    # FormData creation utilities
│   │   └── download_helper.dart     # Download manager with progress
│   └── models/
│       └── example_model.dart       # Example model (optional)
└── api_utility.dart                 # Main export file

example/
└── example_usage.dart               # Complete usage examples
```

## ✨ Features

- ✅ **Complete HTTP Methods**: GET, POST, PUT, DELETE, PATCH
- ✅ **Global Configuration**: Base URL, headers, timeouts, retry settings
- ✅ **Exception Handling**: Structured error handling with custom ApiException
- ✅ **Auto-Retry**: Configurable retry with exponential backoff
- ✅ **Internet Checking**: Automatic connectivity verification
- ✅ **File Upload**: Single and multiple file uploads with FormData
- ✅ **File Download**: Progress tracking, pause/resume support
- ✅ **Parallel Requests**: Execute multiple requests simultaneously
- ✅ **Beautiful Logging**: Color-coded, detailed console logs
- ✅ **Local Override**: Override global settings per request
- ✅ **Generic Response**: Type-safe response handling
- ✅ **State Management Ready**: Works with GetX, Bloc, Riverpod, Provider
- ✅ **Production Ready**: Memory leak free, optimized performance

## 🚀 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  path_provider: ^2.1.1
```

## 📖 Usage

### 1. Initialize the Package

```dart
import 'package:api_utility/api_utility.dart';

void main() {
  // Initialize API Service
  ApiService().initialize();
  
  // Configure settings
  ApiConfig().initialize(
    baseUrl: 'https://api.example.com',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    enableLogs: true,
    enableRetry: true,
    retryCount: 3,
    retryDelay: Duration(seconds: 2),
    exponentialBackoff: true,
    globalExceptionHandler: (exception) {
      print('Global Error: ${exception.message}');
    },
    onUnauthorized: () {
      // Redirect to login
      print('Session expired!');
    },
  );
  
  runApp(MyApp());
}
```

### 2. Basic API Calls

#### GET Request
```dart
final response = await ApiService().get('/posts');

if (response.isSuccess) {
  print('Data: ${response.raw}');
} else {
  print('Error: ${response.error?.message}');
}
```

#### POST Request
```dart
final response = await ApiService().post(
  '/posts',
  data: {
    'title': 'New Post',
    'body': 'Content here',
    'userId': 1,
  },
);
```

#### PUT Request
```dart
final response = await ApiService().put(
  '/posts/1',
  data: {'title': 'Updated Title'},
);
```

#### DELETE Request
```dart
final response = await ApiService().delete('/posts/1');
```

### 3. With Custom Parser

```dart
final response = await ApiService().get<Post>(
  '/posts/1',
  parser: (data) => Post.fromJson(data),
);

if (response.isSuccess && response.data != null) {
  Post post = response.data!;
  print('Title: ${post.title}');
}
```

### 4. Local Override Options

```dart
final response = await ApiService().get(
  '/posts',
  retry: true,                    // Override global retry setting
  checkInternet: false,           // Skip internet check
  timeout: Duration(seconds: 60), // Custom timeout
  overrideGlobalError: true,      // Handle errors manually
  headers: {
    'X-Custom': 'value',          // Additional headers
  },
);
```

### 5. Parallel Requests

```dart
final responses = await ApiService().multiRequest([
  ApiService().get('/posts/1'),
  ApiService().get('/posts/2'),
  ApiService().get('/posts/3'),
]);

for (var response in responses) {
  if (response.isSuccess) {
    print('Success: ${response.raw}');
  }
}
```

### 6. File Upload

#### Single File
```dart
final formData = await FormDataHelper.createFormData(
  fields: {'title': 'My Photo'},
  files: {'image': File('path/to/image.jpg')},
);

final response = await ApiService().post('/upload', data: formData);
```

#### Multiple Files
```dart
final files = [
  FileUploadItem(
    file: File('path/image1.jpg'),
    fieldName: 'images',
    filename: 'photo1.jpg',
  ),
  FileUploadItem(
    file: File('path/image2.jpg'),
    fieldName: 'images',
    filename: 'photo2.jpg',
  ),
];

final formData = await FormDataHelper.createFormDataWithMixedFiles(
  fields: {'title': 'Multiple Photos'},
  files: files,
);

final response = await ApiService().post('/upload', data: formData);
```

### 7. File Download

#### Single File
```dart
final result = await ApiService().downloadFile(
  url: 'https://example.com/file.pdf',
  savePath: '/path/to/save/file.pdf',
  onProgress: (received, total) {
    print('Progress: ${(received / total * 100).toStringAsFixed(1)}%');
  },
);

if (result.success) {
  print('Downloaded: ${result.filePath}');
  print('Size: ${result.formattedFileSize}');
}
```

#### Multiple Files
```dart
final urls = [
  'https://example.com/file1.pdf',
  'https://example.com/file2.pdf',
];

final results = await ApiService().downloadMultiple(
  urls: urls,
  saveDirectory: '/path/to/save',
  onProgress: (url, received, total) {
    print('$url: ${(received / total * 100).toStringAsFixed(1)}%');
  },
);
```

### 8. Response Handling

#### Chain Methods
```dart
await ApiService().get('/posts/1')
  .then((response) {
    return response
      .onSuccess((data) {
        print('Success: $data');
      })
      .onError((error) {
        print('Error: ${error.message}');
      });
  });
```

#### Transform Response
```dart
final response = await ApiService().get<Map>('/posts/1');

final transformed = response.transform<String>(
  (data) => data?['title'] ?? 'No title',
);

print(transformed.data); // Returns String
```

### 9. Error Handling

#### Global Handler
```dart
ApiConfig().setGlobalExceptionHandler((exception) {
  if (exception.isNetworkError) {
    showDialog('No internet connection');
  } else if (exception.isAuthError) {
    navigateToLogin();
  } else {
    showSnackBar(exception.message);
  }
});
```

#### Manual Handler
```dart
final response = await ApiService().get(
  '/posts',
  overrideGlobalError: true,
);

if (response.isError) {
  final error = response.error!;
  
  switch (error.type) {
    case ApiExceptionType.timeout:
      print('Request timeout');
      break;
    case ApiExceptionType.unauthorized:
      print('Please login');
      break;
    case ApiExceptionType.noInternet:
      print('No connection');
      break;
    default:
      print('Error: ${error.message}');
  }
}
```

### 10. Runtime Configuration Updates

```dart
// Update base URL
ApiConfig().updateBaseUrl('https://new-api.example.com');

// Update token (after login)
ApiConfig().updateToken('new-auth-token');

// Add custom header
ApiConfig().addHeader('X-Custom', 'value');

// Update retry settings
ApiConfig().updateRetryConfig(
  enableRetry: true,
  retryCount: 5,
  exponentialBackoff: true,
);

// Toggle logging
ApiConfig().setLogging(false);
```

## 🎯 Use Cases

### With GetX
```dart
class UserController extends GetxController {
  final ApiService _api = ApiService();
  
  Future<void> fetchUser() async {
    final response = await _api.get('/user');
    if (response.isSuccess) {
      // Update state
    }
  }
}
```

### With Bloc
```dart
class ApiRepository {
  final ApiService _api = ApiService();
  
  Future<List<Post>> getPosts() async {
    final response = await _api.get<List<Post>>(
      '/posts',
      parser: (data) => (data as List)
          .map((json) => Post.fromJson(json))
          .toList(),
    );
    return response.dataOrThrow;
  }
}
```

### With Riverpod
```dart
final apiProvider = Provider((ref) => ApiService());

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final api = ref.read(apiProvider);
  final response = await api.get<List<Post>>(
    '/posts',
    parser: (data) => (data as List)
        .map((json) => Post.fromJson(json))
        .toList(),
  );
  return response.dataOrThrow;
});
```

## 📊 Console Logging

The package provides beautiful, color-coded console logs:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 API REQUEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GET https://api.example.com/posts
⏰ Time: 14:30:45.123

📋 Headers:
  Content-Type: application/json
  Authorization: Bearer token

📦 Request Body:
{
  "page": 1,
  "limit": 10
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📥 API RESPONSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status Code: 200 ✅
https://api.example.com/posts
⏱️  Duration: 245ms
⏰ Time: 14:30:45.368

📦 Response Body:
[
  {
    "id": 1,
    "title": "Post Title"
  }
]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔧 Advanced Features

### Auto-Retry with Exponential Backoff
```dart
ApiConfig().updateRetryConfig(
  enableRetry: true,
  retryCount: 3,
  retryDelay: Duration(seconds: 2),
  exponentialBackoff: true, // 2s, 4s, 8s
);
```

### Internet Connectivity
```dart
// Check before each request (enabled by default)
final hasInternet = await ApiService().networkChecker.checkConnectivity();

// Listen to connectivity changes
ApiService().networkChecker.connectionStatusStream.listen((isConnected) {
  print('Internet: ${isConnected ? "Connected" : "Disconnected"}');
});
```

### Cancel Downloads
```dart
// Cancel specific download
ApiService().cancelDownload('https://example.com/file.pdf');

// Cancel all downloads
ApiService().cancelAllDownloads();
```

## 🎨 Best Practices

1. **Initialize Once**: Call `ApiService().initialize()` at app startup
2. **Use Parsers**: Parse responses to models for type safety
3. **Handle Errors Globally**: Set up global exception handler for consistent UX
4. **Enable Logging in Debug**: Keep logs enabled during development
5. **Use Local Override Sparingly**: Override only when necessary
6. **Clean Up**: Call `ApiService().dispose()` when done

## 📝 License

MIT License - feel free to use in your projects!

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit PRs.

## 📧 Support

For issues or questions, please open an issue on GitHub.

---

Made with ❤️ for Flutter developers 