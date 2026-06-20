# gt_api

[![pub package](https://img.shields.io/pub/v/gt_api.svg)](https://pub.dev/packages/gt_api)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A robust, elegant, and production-ready HTTP/REST client wrapper for Flutter and Dart applications built on top of `Dio`. Designed to streamline RESTful API integrations, state management, auto-retries, network checks, console logging, and file download/upload flows.

---

## Features

- ⚡ **Complete HTTP Methods**: Simple wrapper for `GET`, `POST`, `PUT`, `DELETE`, and `PATCH` requests.
- ⚙️ **Centralized Configuration**: Global configuration using `ApiConfig` (base URL, headers, timeouts) with local request overrides.
- 🔄 **Auto-Retry Interceptor**: Automatic request retries with configurable delay and optional exponential backoff.
- 📶 **Network Connectivity Verification**: Automatic checks for active internet connections before making network calls.
- 📊 **Unified Responses**: Structured responses with type-safe generic parsing (`ApiResponse<T>`).
- 📁 **File Upload Helper**: Multi-part `FormData` builder supporting field attributes, single files, and mixed list uploads.
- 📥 **File Download Manager**: Download files, images, and videos with progress callbacks and cancel support.
- 🪵 **Beautiful Console Logger**: Rich ANSI color-coded console logs for requests, responses, and errors.

---

## Installation

Add `gt_api` to your `pubspec.yaml`:

```yaml
dependencies:
  gt_api:
    path: path/to/gt_api # Or version constraint once published
```

Or run:

```bash
flutter pub add gt_api
```

---

## Getting Started

### 1. Initialize API Configurations
Before calling any API methods, initialize the settings via the `ApiConfig` singleton and trigger initialization on the central `ApiService`. This is typically done in your app's entrypoint (`main.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:gt_api/gt_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Configure global settings
  ApiConfig().initialize(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    enableLogs: true,
    enableRetry: true,
    retryCount: 3,
    retryDelay: const Duration(seconds: 2),
    exponentialBackoff: true,
    onUnauthorized: () {
      // Handle 401 Unauthorized responses globally (e.g. redirect to login screen)
      print('User token is expired or invalid.');
    },
  );

  // 2. Initialize the ApiService
  ApiService().initialize();

  runApp(const MyApp());
}
```

---

## Core Usage Examples

### GET Request with Automatic Parsing
You can perform GET requests and automatically map JSON map objects to your Dart model classes using the `parser` attribute:

```dart
// Model definition
class Post {
  final int id;
  final String title;
  final String body;

  Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}

// Fetching single post
Future<void> fetchPost() async {
  final response = await ApiService().get<Post>(
    '/posts/1',
    parser: (data) => Post.fromJson(data),
  );

  if (response.isSuccess && response.data != null) {
    Post post = response.data!;
    print('Title: ${post.title}');
  } else {
    print('Error: ${response.error?.message}');
  }
}
```

### POST Request (Sending Body Data)
```dart
Future<void> createPost() async {
  final response = await ApiService().post(
    '/posts',
    data: {
      'title': 'New Post Title',
      'body': 'This is the body of the new post.',
      'userId': 1,
    },
  );

  if (response.isSuccess) {
    print('Post created. Server returned: ${response.raw}');
  } else {
    print('Failed: ${response.error?.message}');
  }
}
```

### Parallel Requests
Execute multiple endpoints simultaneously and wait for all results in a single non-blocking stream:

```dart
Future<void> loadDashboard() async {
  final responses = await ApiService().multiRequest([
    ApiService().get('/profile'),
    ApiService().get('/notifications'),
    ApiService().get('/dashboard-stats'),
  ]);

  final profileSuccess = responses[0].isSuccess;
  final statsData = responses[2].raw;
  print('Dashboard status: $profileSuccess, Stats: $statsData');
}
```

### Uploading Files (FormData)
Using the `FormDataHelper` utility, creating and sending multipart records containing files is extremely simple:

```dart
import 'dart:io';
import 'package:gt_api/gt_api.dart';

Future<void> uploadUserProfile(File imageFile) async {
  final formData = await FormDataHelper.createFormData(
    fields: {
      'name': 'John Doe',
      'role': 'Developer',
    },
    files: {
      'avatar': imageFile,
    },
  );

  final response = await ApiService().post(
    '/user/profile-upload',
    data: formData,
  );

  if (response.isSuccess) {
    print('Profile and avatar uploaded successfully.');
  }
}
```

### Downloading Files with Progress Callbacks
You can download raw documents, images, or videos directly into the app documents directory and track progress:

```dart
Future<void> downloadDocument() async {
  final result = await ApiService().downloadFile(
    url: 'https://example.com/assets/report.pdf',
    filename: 'annual_report.pdf',
    onProgress: (received, total) {
      if (total != -1) {
        final percent = (received / total * 100).toStringAsFixed(1);
        print('Downloaded: $percent%');
      }
    },
  );

  if (result.success) {
    print('File saved to: ${result.filePath}');
  } else {
    print('Download failed: ${result.error}');
  }
}
```

---

## Advanced Configurations

### Token Authorization Management
You can set and refresh auth tokens dynamically at runtime (e.g. after user logs in):

```dart
// Inject Auth Token
ApiConfig().updateToken('ey...',);

// Clear Token on Logout
ApiConfig().updateToken(null);
```

### Listening to Connection Status
Use the `NetworkChecker` singleton to listen to connectivity status stream throughout your application:

```dart
NetworkChecker().connectionStatusStream.listen((bool isConnected) {
  if (!isConnected) {
    print('Device is offline! Show warning banner.');
  } else {
    print('Device is back online.');
  }
});
```

---

## License

This package is licensed under the MIT License. See [LICENSE](LICENSE) for details.
