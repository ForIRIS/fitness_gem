import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool _isUsingMockData = false;

  bool get isConnected => _isConnected;
  bool get isUsingMockData => _isUsingMockData;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final _mockDataController = StreamController<bool>.broadcast();
  Stream<bool> get mockDataStream => _mockDataController.stream;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected =
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      debugPrint(
        'ConnectivityService: Connection status changed to $_isConnected',
      );
      _connectionController.add(_isConnected);

      // If we regain connection, reset mock data flag
      if (_isConnected && _isUsingMockData) {
        _isUsingMockData = false;
        _mockDataController.add(false);
      }
    }
  }

  /// Mark that mock data is being used due to connection issues
  void setUsingMockData(bool value) {
    if (_isUsingMockData != value) {
      _isUsingMockData = value;
      debugPrint('ConnectivityService: Using mock data = $value');
      _mockDataController.add(value);
    }
  }

  /// Check if we can reach the network
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
    return _isConnected;
  }

  void dispose() {
    _subscription?.cancel();
    _connectionController.close();
    _mockDataController.close();
  }
}
