import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_config.dart';
import 'logger.dart';

/// Download Manager for file downloads with progress tracking
class DownloadHelper {
  final Dio _dio;
  final ApiConfig _config;
  final ApiLogger _logger;

  /// Active downloads map (url -> CancelToken)
  final Map<String, CancelToken> _activeDownloads = {};

  DownloadHelper({
    required this._dio,
    required this._config,
    required this._logger,
  });

  /// Download file from URL
  Future<DownloadResult> downloadFile({
    required String url,
    String? savePath,
    String? filename,
    Map<String, dynamic>? headers,
    Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      // Determine save path
      final filePath = await _determineFilePath(savePath, filename, url);

      // Create cancel token if not provided
      final token = cancelToken ?? CancelToken();

      // Store active download
      _activeDownloads[url] = token;

      // Log download start
      _logger.log('📥 Starting download: $url');
      _logger.log('💾 Save path: $filePath');

      final startTime = DateTime.now();

      // Download file
      await _dio.download(
        url,
        filePath,
        options: Options(
          headers: {..._config.globalHeaders, ...?headers},
          receiveTimeout: _config.receiveTimeout,
        ),
        cancelToken: token,
        onReceiveProgress: (received, total) {
          // Call progress callback
          onProgress?.call(received, total);

          // Log progress
          if (_config.enableLogs && total != -1) {
            _logger.logDownloadProgress(
              url: url,
              received: received,
              total: total,
            );
          }
        },
        deleteOnError: true,
      );

      // Remove from active downloads
      _activeDownloads.remove(url);

      final duration = DateTime.now().difference(startTime);
      final file = File(filePath);
      final fileSize = file.lengthSync();

      _logger.log(
        '✅ Download completed in ${duration.inMilliseconds}ms | Size: ${_formatBytes(fileSize)}',
      );

      return DownloadResult(
        success: true,
        filePath: filePath,
        fileSize: fileSize,
        duration: duration,
      );
    } on DioException catch (e) {
      _activeDownloads.remove(url);

      if (e.type == DioExceptionType.cancel) {
        _logger.log('Download cancelled: $url', isError: true);
        return DownloadResult(success: false, error: 'Download cancelled');
      }

      _logger.log('Download failed: ${e.message}', isError: true);
      return DownloadResult(
        success: false,
        error: e.message ?? 'Download failed',
      );
    } catch (e) {
      _activeDownloads.remove(url);
      _logger.log('Download failed: $e', isError: true);
      return DownloadResult(success: false, error: e.toString());
    }
  }

  /// Download multiple files in parallel
  Future<List<DownloadResult>> downloadMultiple({
    required List<String> urls,
    String? saveDirectory,
    Map<String, dynamic>? headers,
    Function(String url, int received, int total)? onProgress,
  }) async {
    _logger.log('📥 Starting ${urls.length} downloads in parallel...');

    final results = await Future.wait(
      urls.map(
        (url) => downloadFile(
          url: url,
          savePath: saveDirectory,
          headers: headers,
          onProgress: onProgress != null
              ? (received, total) => onProgress(url, received, total)
              : null,
        ),
      ),
    );

    final successCount = results.where((r) => r.success).length;
    _logger.log(
      '✅ Completed $successCount/${urls.length} downloads successfully',
    );

    return results;
  }

  /// Download image
  Future<DownloadResult> downloadImage({
    required String url,
    String? savePath,
    String? filename,
    Map<String, dynamic>? headers,
    Function(int received, int total)? onProgress,
  }) async {
    return downloadFile(
      url: url,
      savePath: savePath,
      filename:
          filename ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
  }) async {
    return downloadFile(
      url: url,
      savePath: savePath,
      filename:
          filename ?? 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      headers: headers,
      onProgress: onProgress,
    );
  }

  /// Cancel download
  void cancelDownload(String url) {
    final token = _activeDownloads[url];
    if (token != null && !token.isCancelled) {
      token.cancel('Download cancelled by user');
      _activeDownloads.remove(url);
      _logger.log('🚫 Download cancelled: $url');
    }
  }

  /// Cancel all active downloads
  void cancelAllDownloads() {
    for (var token in _activeDownloads.values) {
      if (!token.isCancelled) {
        token.cancel('All downloads cancelled');
      }
    }
    _activeDownloads.clear();
    _logger.log('🚫 All downloads cancelled');
  }

  /// Check if download is active
  bool isDownloadActive(String url) {
    return _activeDownloads.containsKey(url);
  }

  /// Get active downloads count
  int get activeDownloadsCount => _activeDownloads.length;

  /// Determine file path for download
  Future<String> _determineFilePath(
    String? savePath,
    String? filename,
    String url,
  ) async {
    // If full path is provided, use it
    if (savePath != null && savePath.endsWith('/') == false) {
      return savePath;
    }

    // Determine directory
    String directory;
    if (savePath != null) {
      directory = savePath;
    } else {
      // Use app's documents directory
      final dir = await getApplicationDocumentsDirectory();
      directory = dir.path;
    }

    // Determine filename
    String finalFilename;
    if (filename != null) {
      finalFilename = filename;
    } else {
      // Extract filename from URL
      final uri = Uri.parse(url);
      finalFilename = uri.pathSegments.last;

      // If no filename in URL, generate one
      if (finalFilename.isEmpty || !finalFilename.contains('.')) {
        finalFilename = 'download_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    return '$directory/$finalFilename';
  }

  /// Format bytes to human-readable format
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Download result model
class DownloadResult {
  final bool success;
  final String? filePath;
  final int? fileSize;
  final Duration? duration;
  final String? error;

  DownloadResult({
    required this.success,
    this.filePath,
    this.fileSize,
    this.duration,
    this.error,
  });

  /// Get file size in human-readable format
  String? get formattedFileSize {
    if (fileSize == null) return null;
    return _formatBytes(fileSize!);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  String toString() {
    if (success) {
      return 'DownloadResult.success(path: $filePath, size: $formattedFileSize, duration: ${duration?.inMilliseconds}ms)';
    } else {
      return 'DownloadResult.error(error: $error)';
    }
  }
}
