import 'package:flutter/material.dart';
import 'package:gt_api/gt_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gt_api Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: const ApiExampleScreen(),
    );
  }
}

class ApiExampleScreen extends StatefulWidget {
  const ApiExampleScreen({super.key});

  @override
  State<ApiExampleScreen> createState() => _ApiExampleScreenState();
}

class _ApiExampleScreenState extends State<ApiExampleScreen> {
  final ApiService _apiService = ApiService();
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  /// Initialize API configuration
  void _initializeApi() {
    // Configure global API settings
    ApiConfig().initialize(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      enableLogs: true,
      enableRetry: true,
      retryCount: 3,
      retryDelay: const Duration(seconds: 1),
    );

    // Initialize API Service singleton
    _apiService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Utility Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result display
            Container(
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 250),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _result.isEmpty ? 'Results will appear here' : _result,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Loading indicator
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
            ],

            // Example buttons
            _buildExampleButton(
              'GET Request',
              'Fetch posts from API',
              _exampleGetRequest,
            ),
            _buildExampleButton(
              'POST Request',
              'Create a new post',
              _examplePostRequest,
            ),
            _buildExampleButton(
              'PUT Request',
              'Update existing post',
              _examplePutRequest,
            ),
            _buildExampleButton(
              'DELETE Request',
              'Delete a post',
              _exampleDeleteRequest,
            ),
            _buildExampleButton(
              'With Custom Parser',
              'Parse response to model',
              _exampleWithParser,
            ),
            _buildExampleButton(
              'Parallel Requests',
              'Execute multiple requests simultaneously',
              _exampleParallelRequests,
            ),
            _buildExampleButton(
              'With Retry',
              'Request with auto-retry on failure',
              _exampleWithRetry,
            ),
            _buildExampleButton(
              'Override Global Error',
              'Handle errors manually',
              _exampleOverrideGlobalError,
            ),
            _buildExampleButton(
              'Upload File (FormData)',
              'Upload field metadata with FormData helper',
              _exampleFileUpload,
            ),
            _buildExampleButton(
              'Download File',
              'Download file with progress indicator',
              _exampleDownloadFile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleButton(
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _isLoading ? null : onTap,
      ),
    );
  }

  /// Example 1: GET Request
  Future<void> _exampleGetRequest() async {
    _setLoading(true);

    final response = await _apiService.get(
      '/posts',
      queryParameters: {'_limit': '5'},
    );

    if (response.isSuccess) {
      _setResult(
        '✅ Success!\nReceived ${(response.raw as List).length} posts:\n\n${response.raw.toString()}',
      );
    } else {
      _setResult('❌ Error: ${response.error?.message}');
    }

    _setLoading(false);
  }

  /// Example 2: POST Request
  Future<void> _examplePostRequest() async {
    _setLoading(true);

    final response = await _apiService.post(
      '/posts',
      data: {
        'title': 'New Post',
        'body': 'This is a test post created using API Utility',
        'userId': 1,
      },
    );

    if (response.isSuccess) {
      _setResult(
        '✅ Post Created!\nID: ${response.raw['id']}\nData: ${response.raw}',
      );
    } else {
      _setResult('❌ Error: ${response.error?.message}');
    }

    _setLoading(false);
  }

  /// Example 3: PUT Request
  Future<void> _examplePutRequest() async {
    _setLoading(true);

    final response = await _apiService.put(
      '/posts/1',
      data: {
        'id': 1,
        'title': 'Updated Post',
        'body': 'This post has been updated',
        'userId': 1,
      },
    );

    if (response.isSuccess) {
      _setResult(
        '✅ Post Updated!\nTitle: ${response.raw['title']}\nData: ${response.raw}',
      );
    } else {
      _setResult('❌ Error: ${response.error?.message}');
    }

    _setLoading(false);
  }

  /// Example 4: DELETE Request
  Future<void> _exampleDeleteRequest() async {
    _setLoading(true);

    final response = await _apiService.delete('/posts/1');

    if (response.isSuccess) {
      _setResult('✅ Post Deleted Successfully!');
    } else {
      _setResult('❌ Error: ${response.error?.message}');
    }

    _setLoading(false);
  }

  /// Example 5: With Custom Parser
  Future<void> _exampleWithParser() async {
    _setLoading(true);

    final response = await _apiService.get<Post>(
      '/posts/1',
      parser: (data) => Post.fromJson(data),
    );

    if (response.isSuccess && response.data != null) {
      final post = response.data!;
      _setResult('✅ Parsed Post:\nTitle: ${post.title}\nBody: ${post.body}');
    } else {
      _setResult('❌ Error: ${response.error?.message}');
    }

    _setLoading(false);
  }

  /// Example 6: Parallel Requests
  Future<void> _exampleParallelRequests() async {
    _setLoading(true);

    final responses = await _apiService.multiRequest([
      _apiService.get('/posts/1'),
      _apiService.get('/posts/2'),
      _apiService.get('/posts/3'),
    ]);

    final successCount = responses.where((r) => r.isSuccess).length;
    _setResult(
      '✅ Completed!\n$successCount/${responses.length} requests succeeded',
    );

    _setLoading(false);
  }

  /// Example 7: With Retry
  Future<void> _exampleWithRetry() async {
    _setLoading(true);

    final response = await _apiService.get(
      '/posts/1',
      retry: true, // Enable retry for this request
    );

    if (response.isSuccess) {
      _setResult('✅ Success with retry support!');
    } else {
      _setResult('❌ Failed after retries: ${response.error?.message}');
    }

    _setLoading(false);
  }

  /// Example 8: Override Global Error Handler
  Future<void> _exampleOverrideGlobalError() async {
    _setLoading(true);

    final response = await _apiService.get(
      '/invalid-endpoint',
      overrideGlobalError: true, // Handle error manually
    );

    if (response.isError) {
      _setResult(
        '❌ Manual Error Handling:\n'
        'Type: ${response.error?.type}\n'
        'Message: ${response.error?.message}\n'
        'Status: ${response.statusCode}',
      );
    }

    _setLoading(false);
  }

  /// Example 9: File Upload
  Future<void> _exampleFileUpload() async {
    _setLoading(true);

    try {
      // Create FormData using helper
      final formData = await FormDataHelper.createFormData(
        fields: {
          'title': 'My Photo',
          'description': 'Uploaded via API Utility',
        },
      );

      final response = await _apiService.post('/posts', data: formData);

      if (response.isSuccess) {
        _setResult('✅ Fields parsed into FormData and sent successfully!');
      } else {
        _setResult('❌ Upload failed: ${response.error?.message}');
      }
    } catch (e) {
      _setResult('❌ Error creating FormData: $e');
    }

    _setLoading(false);
  }

  /// Example 10: Download File
  Future<void> _exampleDownloadFile() async {
    _setLoading(true);

    final result = await _apiService.downloadImage(
      url: 'https://via.placeholder.com/600/92c952',
      filename: 'sample_image.jpg',
      onProgress: (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).toStringAsFixed(1);
          setState(() {
            _result = '📥 Downloading: $progress%';
          });
        }
      },
    );

    if (result.success) {
      _setResult(
        '✅ Downloaded!\n'
        'Path: ${result.filePath}\n'
        'Size: ${result.formattedFileSize}\n'
        'Duration: ${result.duration?.inMilliseconds}ms',
      );
    } else {
      _setResult('❌ Download failed: ${result.error}');
    }

    _setLoading(false);
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }

  void _setResult(String result) {
    if (mounted) {
      setState(() => _result = result);
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}

/// Example Post Model
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      body: json['body'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'userId': userId, 'title': title, 'body': body};
  }
}
