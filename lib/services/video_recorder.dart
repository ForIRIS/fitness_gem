import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';

/// VideoRecorder - Simple Video Recording Service
/// Records RGB video for Gemini Analysis (No local ControlNet processing needed)
class VideoRecorder {
  // Configuration
  static const int targetFps = 15;
  static const int targetWidth = 640;
  static const int targetHeight = 480;
  static const int highlightSeconds = 10;
  static const int maxHighlightFrames = targetFps * highlightSeconds;

  // State
  bool _isRecording = false;
  String? _sessionId;
  Directory? _tempDir;

  // RGB Recording
  CameraController? _cameraController;
  // ignore: unused_field
  String? _rgbVideoPath;

  // Real-time Stability (for UI only now)
  // ignore: unused_field
  double _lastStability = 1.0;

  // Callbacks
  void Function(Pose?)? onPoseUpdate;

  bool get isRecording => _isRecording;
  String? get sessionId => _sessionId;

  /// Start Recording
  Future<bool> startRecording(CameraController cameraController) async {
    if (_isRecording) return false;

    try {
      _cameraController = cameraController;
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create Temporary Directory
      final appDir = await getApplicationDocumentsDirectory();
      _tempDir = Directory('${appDir.path}/recordings/$_sessionId');
      if (!await _tempDir!.exists()) {
        await _tempDir!.create(recursive: true);
      }

      // Start RGB Recording
      _rgbVideoPath = '${_tempDir!.path}/rgb_video.mp4';
      await _cameraController!.startVideoRecording();

      // No ControlNet Capture for Gemini 3 (Native Vision is sufficient & faster)

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Update Current Pose (Called every frame from CameraView)
  void updatePose(Pose? pose, {double stability = 1.0}) {
    // Just update for callback or UI if needed
    _lastStability = stability;
    if (onPoseUpdate != null) onPoseUpdate!(pose);
  }

  /// Stop Recording and Return File Result
  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;

    try {
      // 1. Process RGB Video
      final rawRgbPath = await _processRawRgbVideo();

      // 2. No Trimming - Full Context for Gemini 3
      final finalRgbPath = rawRgbPath;

      // 3. No ControlNet Video
      final String? controlNetPath = null;

      // 4. Cleanup (if any temp frames were used, but we don't use them anymore)
      // await _cleanupTemporaryFrames();

      return RecordingResult(
        sessionId: _sessionId!,
        rgbVideoPath: finalRgbPath,
        controlNetVideoPath: controlNetPath,
        highlightStartTime: 0.0,
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  Future<String> _processRawRgbVideo() async {
    final rgbXFile = await _cameraController!.stopVideoRecording();
    final rawRgbPath = '${_tempDir!.path}/raw_rgb.mp4';
    await File(rgbXFile.path).copy(rawRgbPath);
    await File(rgbXFile.path).delete();
    return rawRgbPath;
  }

  /// Cancel Recording and Clean up
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _isRecording = false;

    try {
      await _cameraController?.stopVideoRecording();
    } catch (_) {}

    if (_tempDir != null && await _tempDir!.exists()) {
      await _tempDir!.delete(recursive: true);
    }
  }

  /// Dispose
  void dispose() {
    // No timer to dispose
  }
}

/// Recording Result Data Class
class RecordingResult {
  final String sessionId;
  final String rgbVideoPath;
  final String? controlNetVideoPath;
  final double highlightStartTime;

  RecordingResult({
    required this.sessionId,
    required this.rgbVideoPath,
    this.controlNetVideoPath,
    this.highlightStartTime = 0.0,
  });

  File get rgbFile => File(rgbVideoPath);
  File? get controlNetFile =>
      controlNetVideoPath != null ? File(controlNetVideoPath!) : null;
}
