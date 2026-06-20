import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network Checker Utility
/// Checks internet connectivity using connectivity_plus package
class NetworkChecker {
  /// Singleton instance
  static final NetworkChecker _instance = NetworkChecker._internal();
  factory NetworkChecker() => _instance;
  NetworkChecker._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  /// Stream of connection status changes
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Current connection status
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Initialize network checker and listen to connectivity changes
  Future<void> initialize() async {
    // Check initial connectivity
    await checkConnectivity();

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateConnectionStatus(results);
    });
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
      return false;
    }
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;

    // Check if any result indicates connection
    _isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.satellite,
    );

    // Notify listeners if status changed
    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
    }
  }

  /// Check if internet is available (more reliable than just connectivity check)
  Future<bool> hasInternetConnection() async {
    try {
      // First check connectivity
      final hasConnectivity = await checkConnectivity();
      if (!hasConnectivity) return false;

      // You can add additional ping test here if needed
      // For now, we trust the connectivity result
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get connection type
  Future<String> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty) return 'none';

      final result = results.first;
      switch (result) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.other:
          return 'Other';
        case ConnectivityResult.satellite:
          return 'Satellite';
        case ConnectivityResult.none:
          return 'None';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Wait for internet connection (useful for retrying)
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      if (await checkConnectivity()) {
        return true;
      }
      await Future.delayed(checkInterval);
    }

    return false;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }

  /// Reset checker
  void reset() {
    _isConnected = true;
  }
}
