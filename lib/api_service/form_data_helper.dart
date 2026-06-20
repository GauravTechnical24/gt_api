import 'dart:io';
import 'package:dio/dio.dart';

/// Helper class for creating FormData
class FormDataHelper {
  /// Create FormData from Map with optional files
  static Future<FormData> createFormData({
    Map<String, dynamic>? fields,
    Map<String, File>? files,
    Map<String, List<File>>? multipleFiles,
  }) async {
    final formData = FormData();

    // Add regular fields
    if (fields != null) {
      fields.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
    }

    // Add single files
    if (files != null) {
      for (var entry in files.entries) {
        if (entry.value.existsSync()) {
          final multipartFile = await MultipartFile.fromFile(
            entry.value.path,
            filename: entry.value.path.split('/').last,
          );
          formData.files.add(MapEntry(entry.key, multipartFile));
        }
      }
    }

    // Add multiple files
    if (multipleFiles != null) {
      for (var entry in multipleFiles.entries) {
        for (var file in entry.value) {
          if (file.existsSync()) {
            final multipartFile = await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            );
            formData.files.add(MapEntry(entry.key, multipartFile));
          }
        }
      }
    }

    return formData;
  }

  /// Create FormData with image files
  static Future<FormData> createFormDataWithImages({
    Map<String, dynamic>? fields,
    required String imageFieldName,
    required List<File> images,
  }) async {
    final formData = FormData();

    // Add regular fields
    if (fields != null) {
      fields.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
    }

    // Add images
    for (var image in images) {
      if (image.existsSync()) {
        final multipartFile = await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        );
        formData.files.add(MapEntry(imageFieldName, multipartFile));
      }
    }

    return formData;
  }

  /// Create FormData with video files
  static Future<FormData> createFormDataWithVideos({
    Map<String, dynamic>? fields,
    required String videoFieldName,
    required List<File> videos,
  }) async {
    final formData = FormData();

    // Add regular fields
    if (fields != null) {
      fields.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
    }

    // Add videos
    for (var video in videos) {
      if (video.existsSync()) {
        final multipartFile = await MultipartFile.fromFile(
          video.path,
          filename: video.path.split('/').last,
        );
        formData.files.add(MapEntry(videoFieldName, multipartFile));
      }
    }

    return formData;
  }

  /// Create FormData with mixed files (images, videos, documents)
  static Future<FormData> createFormDataWithMixedFiles({
    Map<String, dynamic>? fields,
    List<FileUploadItem>? files,
  }) async {
    final formData = FormData();

    // Add regular fields
    if (fields != null) {
      fields.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
    }

    // Add files
    if (files != null) {
      for (var item in files) {
        if (item.file.existsSync()) {
          final multipartFile = await MultipartFile.fromFile(
            item.file.path,
            filename: item.filename ?? item.file.path.split('/').last,
          );
          formData.files.add(MapEntry(item.fieldName, multipartFile));
        }
      }
    }

    return formData;
  }

  /// Create FormData from file path
  static Future<FormData> createFromFilePath({
    Map<String, dynamic>? fields,
    required String fieldName,
    required String filePath,
    String? filename,
  }) async {
    final formData = FormData();

    // Add regular fields
    if (fields != null) {
      fields.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
    }

    // Add file
    final file = File(filePath);
    if (file.existsSync()) {
      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: filename ?? filePath.split('/').last,
      );
      formData.files.add(MapEntry(fieldName, multipartFile));
    }

    return formData;
  }

  /// Get file size in human-readable format
  static String getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Validate file before upload
  static bool validateFile({
    required File file,
    int? maxSizeInBytes,
    List<String>? allowedExtensions,
  }) {
    // Check if file exists
    if (!file.existsSync()) return false;

    // Check file size
    if (maxSizeInBytes != null) {
      if (file.lengthSync() > maxSizeInBytes) return false;
    }

    // Check file extension
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      final extension = file.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) return false;
    }

    return true;
  }
}

/// Model for file upload item
class FileUploadItem {
  final File file;
  final String fieldName;
  final String? filename;

  FileUploadItem({required this.file, required this.fieldName, this.filename});

  /// Get file size
  String get fileSize => FormDataHelper.getFileSize(file);

  /// Get file extension
  String get extension => file.path.split('.').last.toLowerCase();

  /// Check if file is image
  bool get isImage {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(extension);
  }

  /// Check if file is video
  bool get isVideo {
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv'];
    return videoExtensions.contains(extension);
  }

  /// Check if file is document
  bool get isDocument {
    const docExtensions = [
      'pdf',
      'doc',
      'docx',
      'txt',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ];
    return docExtensions.contains(extension);
  }
}
