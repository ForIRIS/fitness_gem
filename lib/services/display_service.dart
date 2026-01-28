import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:presentation_displays/display.dart';

/// DisplayService
/// Manages connection status and data transmission to external displays
class DisplayService {
  final DisplayManager _displayManager = DisplayManager();

  // Stream controller for the list of connected displays
  final StreamController<List<Display>> _displaysController =
      StreamController.broadcast();
  Stream<List<Display>> get displaysStream => _displaysController.stream;

  List<Display> _currentDisplays = [];
  Display? _activeDisplay;

  bool get isConnected => _activeDisplay != null;

  DisplayService() {
    _init();
  }

  Timer? _refreshTimer;

  void _init() {
    // Check initial display list
    _refreshDisplays();

    // Refresh display list every 2 seconds (handling stream API uncertainties)
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _refreshDisplays();
    });
  }

  void dispose() {
    _refreshTimer?.cancel();
    _displaysController.close();
  }

  Future<void> _refreshDisplays() async {
    try {
      final displays = await _displayManager.getDisplays();
      if (displays != null) {
        // Update only when changes occur (simple comparison)
        final newIds = displays.map((d) => d.displayId).join();
        final currentIds = _currentDisplays.map((d) => d.displayId).join();

        if (_currentDisplays.length != displays.length ||
            newIds != currentIds) {
          debugPrint('Displays updated: ${displays.length} found');
          _currentDisplays = displays;
          _displaysController.add(displays);

          // Automatic connection logic
          if (displays.isNotEmpty && _activeDisplay == null) {
            _connectToDisplay(displays.first);
          } else if (displays.isEmpty && _activeDisplay != null) {
            _disconnect();
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting displays: $e');
    }
  }

  Future<void> _connectToDisplay(Display display) async {
    if (display.displayId == null) return;

    try {
      await _displayManager.showSecondaryDisplay(
        displayId: display.displayId!,
        routerName: 'external_dashboard',
      );
      _activeDisplay = display;
      debugPrint('Connected to secondary display: ${display.displayId}');
    } catch (e) {
      debugPrint('Error connecting to display: $e');
    }
  }

  Future<void> _disconnect() async {
    _activeDisplay = null;
    debugPrint('Disconnected from secondary display');
  }

  /// Send data to the external display
  /// [data] must be JSON encodable (e.g., Map)
  Future<void> sendData(Map<String, dynamic> data) async {
    if (_activeDisplay == null) return;
    try {
      // presentation_displays basically provides transferDataToPresentation method
      // Method name might differ by library version, but for 1.0.0:
      await _displayManager.transferDataToPresentation(data);
    } catch (e) {
      // Limit debugPrint to avoid excessive error logs
    }
  }
}
