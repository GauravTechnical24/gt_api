import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gt_api/gt_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Main application widget supporting modern dynamic theme modes.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF6366F1); // Indigo accent

    return MaterialApp(
      title: 'gt_api Example',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
      ),
      home: ApiExampleScreen(
        currentThemeMode: _themeMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}

/// Modern interactive demonstration screen for `gt_api`.
class ApiExampleScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const ApiExampleScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  State<ApiExampleScreen> createState() => _ApiExampleScreenState();
}

class _ApiExampleScreenState extends State<ApiExampleScreen> {
  final ApiService _apiService = ApiService();
  String _result = '';
  String _statusBadge = 'Idle';
  Color _statusBadgeColor = Colors.grey;
  bool _isLoading = false;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  /// Initialize API configuration
  void _initializeApi() {
    ApiConfig().initialize(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      enableLogs: true,
      enableRetry: true,
      retryCount: 3,
      retryDelay: const Duration(seconds: 1),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    );

    _apiService.initialize();
  }

  void _setLoading(bool loading, {String status = 'Loading...'}) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) {
          _statusBadge = status;
          _statusBadgeColor = Colors.amber;
          _downloadProgress = null;
        }
      });
    }
  }

  void _setResult(String result, {bool isSuccess = true, String? status}) {
    if (mounted) {
      setState(() {
        _result = result;
        _isLoading = false;
        _statusBadge = status ?? (isSuccess ? 'Success (200 OK)' : 'Error');
        _statusBadgeColor = isSuccess ? Colors.green : Colors.red;
      });
    }
  }

  void _copyResult() {
    if (_result.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _result));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearResult() {
    setState(() {
      _result = '';
      _statusBadge = 'Idle';
      _statusBadgeColor = Colors.grey;
      _downloadProgress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Utility Examples',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'gt_api client interactive test suite',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: Icon(
              widget.currentThemeMode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : widget.currentThemeMode == ThemeMode.light
                  ? Icons.light_mode_rounded
                  : Icons.brightness_auto_rounded,
            ),
            tooltip: 'Select theme',
            onSelected: widget.onThemeChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.brightness_auto_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('System Default'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Light Mode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Dark Mode'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEnvironmentCard(theme, isDark),
                  const SizedBox(height: 16),
                  _buildConsoleCard(theme, isDark),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    theme,
                    'REST Operations',
                    Icons.http_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildActionGrid([
                    _ActionItem(
                      title: 'GET Request',
                      subtitle: 'Fetch 5 posts',
                      badge: 'GET',
                      badgeColor: Colors.blue,
                      icon: Icons.download_rounded,
                      onTap: _exampleGetRequest,
                    ),
                    _ActionItem(
                      title: 'POST Request',
                      subtitle: 'Create post record',
                      badge: 'POST',
                      badgeColor: Colors.green,
                      icon: Icons.upload_rounded,
                      onTap: _examplePostRequest,
                    ),
                    _ActionItem(
                      title: 'PUT Request',
                      subtitle: 'Update existing post',
                      badge: 'PUT',
                      badgeColor: Colors.orange,
                      icon: Icons.edit_note_rounded,
                      onTap: _examplePutRequest,
                    ),
                    _ActionItem(
                      title: 'DELETE Request',
                      subtitle: 'Delete post by ID',
                      badge: 'DEL',
                      badgeColor: Colors.red,
                      icon: Icons.delete_outline_rounded,
                      onTap: _exampleDeleteRequest,
                    ),
                    _ActionItem(
                      title: 'Custom Parser',
                      subtitle: 'Parse JSON to Post model',
                      badge: 'MODEL',
                      badgeColor: Colors.purple,
                      icon: Icons.data_object_rounded,
                      onTap: _exampleWithParser,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    theme,
                    'Advanced Networking',
                    Icons.alt_route_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildActionGrid([
                    _ActionItem(
                      title: 'Parallel Requests',
                      subtitle: 'Run 3 simultaneous calls',
                      badge: 'ASYNC',
                      badgeColor: Colors.teal,
                      icon: Icons.splitscreen_rounded,
                      onTap: _exampleParallelRequests,
                    ),
                    _ActionItem(
                      title: 'Auto Retry',
                      subtitle: 'Exponential backoff retry',
                      badge: 'RETRY',
                      badgeColor: Colors.amber.shade800,
                      icon: Icons.replay_rounded,
                      onTap: _exampleWithRetry,
                    ),
                    _ActionItem(
                      title: 'Error Handling',
                      subtitle: 'Manual error override',
                      badge: 'CATCH',
                      badgeColor: Colors.deepOrange,
                      icon: Icons.gpp_bad_outlined,
                      onTap: _exampleOverrideGlobalError,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    theme,
                    'Media & Transfer',
                    Icons.cloud_sync_rounded,
                  ),
                  const SizedBox(height: 8),
                  _buildActionGrid([
                    _ActionItem(
                      title: 'Upload (FormData)',
                      subtitle: 'Multipart field upload',
                      badge: 'UPLOAD',
                      badgeColor: Colors.indigo,
                      icon: Icons.cloud_upload_outlined,
                      onTap: _exampleFileUpload,
                    ),
                    _ActionItem(
                      title: 'Download File',
                      subtitle: 'Stream with progress callback',
                      badge: 'STREAM',
                      badgeColor: Colors.cyan.shade700,
                      icon: Icons.file_download_outlined,
                      onTap: _exampleDownloadFile,
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(ThemeData theme, bool isDark) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.cloud_done_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected Gateway',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Text(
                    'https://jsonplaceholder.typicode.com',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Colors.green),
                  SizedBox(width: 5),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleCard(ThemeData theme, bool isDark) {
    final consoleBg = isDark
        ? const Color(0xFF13151A)
        : const Color(0xFF1E293B);

    return Container(
      decoration: BoxDecoration(
        color: consoleBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Console header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Row(
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: Color(0xFFEF4444)),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 5, backgroundColor: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 5, backgroundColor: Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(width: 12),
                const Text(
                  'Console Output',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBadgeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusBadgeColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    _statusBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusBadgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  tooltip: 'Copy',
                  onPressed: _result.isNotEmpty ? _copyResult : null,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  tooltip: 'Clear',
                  onPressed: _result.isNotEmpty ? _clearResult : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (_downloadProgress != null)
            LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 3,
              backgroundColor: const Color(0xFF334155),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF38BDF8),
              ),
            ),
          // Output Body
          Container(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 220),
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: SelectableText(
                _result.isEmpty
                    ? '> Ready. Select an API operation below to test.'
                    : _result,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.45,
                  color: _result.isEmpty
                      ? Colors.white38
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(List<_ActionItem> items) {
    return Column(
      children: items.map((item) => _buildActionCard(item)).toList(),
    );
  }

  Widget _buildActionCard(_ActionItem item) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isLoading ? null : item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 20, color: item.badgeColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Example 1: GET Request
  Future<void> _exampleGetRequest() async {
    _setLoading(true, status: 'GET /posts');

    final response = await _apiService.get(
      '/posts',
      queryParameters: {'_limit': '3'},
    );

    if (response.isSuccess) {
      final list = response.raw as List;
      _setResult(
        'STATUS 200 OK (${response.duration?.inMilliseconds ?? 0}ms)\n'
        'Received ${list.length} items:\n\n'
        '${response.raw}',
        isSuccess: true,
        status: '200 OK',
      );
    } else {
      _setResult(
        'ERROR: ${response.error?.message}',
        isSuccess: false,
        status: 'Failed',
      );
    }
  }

  /// Example 2: POST Request
  Future<void> _examplePostRequest() async {
    _setLoading(true, status: 'POST /posts');

    final response = await _apiService.post(
      '/posts',
      data: {
        'title': 'New Feature Announcement',
        'body': 'gt_api modernized with 160/160 quality score.',
        'userId': 1,
      },
    );

    if (response.isSuccess) {
      _setResult(
        'STATUS 201 CREATED\n'
        'Created Record ID: ${response.raw['id']}\n\n'
        'Payload:\n${response.raw}',
        isSuccess: true,
        status: '201 Created',
      );
    } else {
      _setResult(
        'ERROR: ${response.error?.message}',
        isSuccess: false,
        status: 'Failed',
      );
    }
  }

  /// Example 3: PUT Request
  Future<void> _examplePutRequest() async {
    _setLoading(true, status: 'PUT /posts/1');

    final response = await _apiService.put(
      '/posts/1',
      data: {
        'id': 1,
        'title': 'Updated Post Title',
        'body': 'This content has been patched using gt_api put().',
        'userId': 1,
      },
    );

    if (response.isSuccess) {
      _setResult(
        'STATUS 200 UPDATED\n'
        'Updated Record: ${response.raw}',
        isSuccess: true,
        status: '200 Updated',
      );
    } else {
      _setResult(
        'ERROR: ${response.error?.message}',
        isSuccess: false,
        status: 'Failed',
      );
    }
  }

  /// Example 4: DELETE Request
  Future<void> _exampleDeleteRequest() async {
    _setLoading(true, status: 'DELETE /posts/1');

    final response = await _apiService.delete('/posts/1');

    if (response.isSuccess) {
      _setResult(
        'STATUS 200 DELETED\nPost #1 successfully purged.',
        isSuccess: true,
        status: '200 Deleted',
      );
    } else {
      _setResult(
        'ERROR: ${response.error?.message}',
        isSuccess: false,
        status: 'Failed',
      );
    }
  }

  /// Example 5: With Custom Parser
  Future<void> _exampleWithParser() async {
    _setLoading(true, status: 'GET Model');

    final response = await _apiService.get<Post>(
      '/posts/1',
      parser: (data) => Post.fromJson(data as Map<String, dynamic>),
    );

    if (response.isSuccess && response.data != null) {
      final post = response.data!;
      _setResult(
        'PARSED DART MODEL [Post]:\n'
        '  - ID: ${post.id}\n'
        '  - User ID: ${post.userId}\n'
        '  - Title: ${post.title}\n'
        '  - Body: ${post.body}',
        isSuccess: true,
        status: 'Parsed',
      );
    } else {
      _setResult(
        'ERROR: ${response.error?.message}',
        isSuccess: false,
        status: 'Failed',
      );
    }
  }

  /// Example 6: Parallel Requests
  Future<void> _exampleParallelRequests() async {
    _setLoading(true, status: '3x Parallel');

    final responses = await _apiService.multiRequest([
      _apiService.get('/posts/1'),
      _apiService.get('/posts/2'),
      _apiService.get('/posts/3'),
    ]);

    final successCount = responses.where((r) => r.isSuccess).length;
    _setResult(
      'PARALLEL BATCH COMPLETED:\n'
      'Successfully resolved $successCount of ${responses.length} concurrent requests.',
      isSuccess: successCount == responses.length,
      status: '$successCount/${responses.length} Done',
    );
  }

  /// Example 7: With Retry
  Future<void> _exampleWithRetry() async {
    _setLoading(true, status: 'Retry Mode');

    final response = await _apiService.get('/posts/1', retry: true);

    if (response.isSuccess) {
      _setResult(
        'SUCCESS WITH RETRY INTERCEPTOR ARMED:\n'
        'Request resolved cleanly under active retry policy.\n'
        'Duration: ${response.duration?.inMilliseconds}ms',
        isSuccess: true,
        status: 'Retry Ready',
      );
    } else {
      _setResult(
        'FAILED AFTER RETRIES:\n${response.error?.message}',
        isSuccess: false,
        status: 'Retry Failed',
      );
    }
  }

  /// Example 8: Override Global Error Handler
  Future<void> _exampleOverrideGlobalError() async {
    _setLoading(true, status: 'Manual Error');

    final response = await _apiService.get(
      '/invalid-endpoint-404',
      overrideGlobalError: true,
    );

    if (response.isError) {
      _setResult(
        'MANUAL ERROR CAPTURE:\n'
        '  - Type: ${response.error?.type}\n'
        '  - Status Code: ${response.statusCode}\n'
        '  - Message: ${response.error?.message}',
        isSuccess: false,
        status: '404 Handled',
      );
    } else {
      _setResult('Unexpected success on 404 test.');
    }
  }

  /// Example 9: File Upload
  Future<void> _exampleFileUpload() async {
    _setLoading(true, status: 'FormData Upload');

    try {
      final formData = await FormDataHelper.createFormData(
        fields: {
          'title': 'User Profile Picture',
          'description': 'Modernized gt_api file upload payload',
        },
      );

      final response = await _apiService.post('/posts', data: formData);

      if (response.isSuccess) {
        _setResult(
          'MULTIPART FORMDATA DISPATCHED:\n'
          'Fields serialized and transmitted via FormDataHelper.\n'
          'Server Response: ${response.raw}',
          isSuccess: true,
          status: 'Uploaded',
        );
      } else {
        _setResult(
          'Upload failed: ${response.error?.message}',
          isSuccess: false,
          status: 'Failed',
        );
      }
    } catch (e) {
      _setResult('Error creating FormData: $e', isSuccess: false);
    }
  }

  /// Example 10: Download File
  Future<void> _exampleDownloadFile() async {
    _setLoading(true, status: 'Downloading...');

    final result = await _apiService.downloadImage(
      url: 'https://via.placeholder.com/600/92c952',
      filename: 'sample_image.jpg',
      onProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() {
            _downloadProgress = received / total;
            _statusBadge = '${(_downloadProgress! * 100).toStringAsFixed(0)}%';
          });
        }
      },
    );

    if (result.success) {
      _setResult(
        'DOWNLOAD COMPLETED:\n'
        '  - Target File: ${result.filePath}\n'
        '  - Total Size: ${result.formattedFileSize}\n'
        '  - Duration: ${result.duration?.inMilliseconds}ms',
        isSuccess: true,
        status: 'Downloaded',
      );
    } else {
      _setResult(
        'DOWNLOAD ABORTED: ${result.error}',
        isSuccess: false,
        status: 'Error',
      );
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final VoidCallback onTap;

  _ActionItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.onTap,
  });
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
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'userId': userId, 'title': title, 'body': body};
  }
}
