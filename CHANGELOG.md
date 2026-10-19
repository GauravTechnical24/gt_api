# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-17

### Added
- Explicit top-level multi-platform declarations in `pubspec.yaml` supporting Android, iOS, Windows, Linux, and macOS.
- Support for `DioExceptionType.transformTimeout` in `ApiException` and `RetryInterceptor`.
- Optional `Dio? dio` client injection parameter in `RetryInterceptor` constructor for request retries.
- Enhanced backend error message extraction across all HTTP status codes (`401`, `403`, `404`, `500`, `502`, `503`, `504`) with fallback defaults.
- Comprehensive unit test suite with 27 test cases covering configuration, exception mapping, response models, retry policies, logging, form data, downloads, and connectivity.

### Changed
- Modernized dependency lower bounds to verified stable releases:
  - `dio: ^5.11.1` (from `^5.9.0`)
  - `connectivity_plus: ^7.3.2` (from `^7.0.0`)
  - `path_provider: ^2.1.6` (from `^2.1.5`)
- Replaced unconditional `dart:io` import in `ApiLogger` with `package:flutter/foundation.dart` (`kIsWeb` and `defaultTargetPlatform`).
- Updated top-level library declaration in `lib/gt_api.dart` to modern `library;` syntax.
- Improved dartdoc comment coverage across all public API getters and models to 78.6%+.
- Formatted all package code according to official Dart style guidelines.

### Fixed
- Fixed non-exhaustive switch statement compilation errors caused by unhandled `DioExceptionType.transformTimeout`.
- Resolved dependency lower-bound downgrade analysis errors for `ConnectivityResult.satellite`.
- Fixed potential `StateError` on re-initialization in `NetworkChecker` by safely recreating the broadcast `StreamController` if closed.
- Cleaned up duplicate subscription listeners in `NetworkChecker.initialize()`.
- Removed dead and obsolete files (`api_utility.dart`, `OVERVIEW.md`, `API.md`) from package source.

### Compatibility
- Verified compatibility with Flutter `3.47.7` and Dart `3.13.5`.
- Supported SDK constraints: Flutter `>=3.44.2`, Dart `>=3.12.0 <4.0.0`.
- Verified Android builds against Android SDK 36, AGP 9.0.1, Gradle 9.1.0, and Java 25.
- Verified iOS builds against iOS Deployment Target 15.0 and Xcode 27.1 Swift Package Manager integration.

## [1.1.0] - 2026-10-17

### Changed
- **Flutter SDK Upgrade**: Upgraded package environment and constraints to require Flutter `>=3.44.2` and Dart `>=3.12.0 <4.0.0` (matching Flutter 3.44.2 release).
- **iOS Target Bump**: Upgraded iOS deployment target to 15.0 to ensure compatibility with Swift Package Manager and modern iOS configurations under Flutter 3.44.2.
- Added default Android platform setup in the example project.

## [1.0.0] - 2026-10-17

### Added
- **Initial Release of the Dio-based Custom Client**:
  - `ApiService`: Central API service class for executing HTTP requests (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`) with full response parsing and error mapping.
  - `ApiConfig`: Global runtime configuration support (base URL, global headers, timeouts, error callbacks).
  - `ApiException` & `ApiResponse`: Unified model structures for request errors, success wrappers, and status checks.
  - `DownloadHelper`: Dedicated utility supporting file download (including single/multiple images and videos) with real-time download progress callbacks.
  - `FormDataHelper`: Seamless utility to generate multipart requests, upload files, and mixed uploads.
  - `NetworkChecker`: Internet connection verification with automatic connection status subscription.
  - `RetryInterceptor`: Automatic connection retry wrapper featuring exponential backoff support.
  - `ApiLogger`: Beautifully formatted terminal and console logs for HTTP requests, responses, and errors.
