import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:ffmpeg_kit_flutter_video/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_video/return_code.dart';

/// VideoRecorder - Dual-stream Video Recording Service
/// Records RGB video and ControlNet (Skeleton) video simultaneously
class VideoRecorder {
  // Configuration
  static const int targetFps = 15;
  static const int targetWidth = 640;
  static const int targetHeight = 480;

  // State
  bool _isRecording = false;
  String? _sessionId;
  Directory? _tempDir;

  // RGB Recording
  CameraController? _cameraController;
  String? _rgbVideoPath;

  // ControlNet Frame Capture
  final List<String> _controlNetFramePaths = [];
  int _frameCount = 0;
  Timer? _frameTimer;
  Pose? _currentPose;

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

      // Start ControlNet Frame Capture Timer
      _frameCount = 0;
      _controlNetFramePaths.clear();
      _startControlNetCapture();

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Start ControlNet Frame Capture
  void _startControlNetCapture() {
    // 15fps = approx 66ms interval
    _frameTimer = Timer.periodic(
      Duration(milliseconds: (1000 / targetFps).round()),
      (_) => _captureControlNetFrame(),
    );
  }

  /// Capture ControlNet Frame
  Future<void> _captureControlNetFrame() async {
    if (!_isRecording || _currentPose == null || _tempDir == null) return;

    try {
      final framePath =
          '${_tempDir!.path}/frame_${_frameCount.toString().padLeft(5, '0')}.png';

      // Generate Skeleton Image
      final imageBytes = await _generateSkeletonImage(_currentPose!);
      if (imageBytes != null) {
        await File(framePath).writeAsBytes(imageBytes);
        _controlNetFramePaths.add(framePath);
        _frameCount++;
      }
    } catch (e) {
      debugPrint('Error capturing ControlNet frame: $e');
    }
  }

  /// Generate Skeleton Image (Black Background + White Skeleton)
  Future<Uint8List?> _generateSkeletonImage(Pose pose) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Black Background
      final bgPaint = Paint()..color = const ui.Color(0xFF000000);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        bgPaint,
      );

      // Draw Skeleton
      final paint = Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      final pointPaint = Paint()
        ..color = const ui.Color(0xFF00FF00)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;

      // Define Connections
      final connections = [
        // Face
        [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
        [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
        [PoseLandmarkType.nose, PoseLandmarkType.rightEye],
        [PoseLandmarkType.rightEye, PoseLandmarkType.rightEar],
        // Body
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
        [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
        // Left Arm
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
        // Right Arm
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
        // Left Leg
        [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
        [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
        // Right Leg
        [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
        [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      ];

      // Draw Connections
      for (final connection in connections) {
        final p1 = pose.landmarks[connection[0]];
        final p2 = pose.landmarks[connection[1]];

        if (p1 != null && p2 != null) {
          // Normalize Coordinates (Camera Resolution -> Output Resolution)
          final x1 =
              p1.x / _cameraController!.value.previewSize!.height * targetWidth;
          final y1 =
              p1.y / _cameraController!.value.previewSize!.width * targetHeight;
          final x2 =
              p2.x / _cameraController!.value.previewSize!.height * targetWidth;
          final y2 =
              p2.y / _cameraController!.value.previewSize!.width * targetHeight;

          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        }
      }

      // Draw Joint Points
      for (final landmark in pose.landmarks.values) {
        final x =
            landmark.x /
            _cameraController!.value.previewSize!.height *
            targetWidth;
        final y =
            landmark.y /
            _cameraController!.value.previewSize!.width *
            targetHeight;
        canvas.drawPoints(ui.PointMode.points, [Offset(x, y)], pointPaint);
      }

      // Convert to Image
      final picture = recorder.endRecording();
      final image = await picture.toImage(targetWidth, targetHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating skeleton image: $e');
      return null;
    }
  }

  /// Update Current Pose (Called every frame)
  void updatePose(Pose? pose) {
    _currentPose = pose;
  }

  /// Stop Recording and Return File
  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;
    _frameTimer?.cancel();

    try {
      // Stop RGB Recording
      final rgbFile = await _cameraController!.stopVideoRecording();

      // Move RGB file to desired location
      final rgbDestPath = '${_tempDir!.path}/rgb_video.mp4';
      await File(rgbFile.path).copy(rgbDestPath);
      await File(rgbFile.path).delete();

      // Convert ControlNet frames to video
      String? controlNetPath;
      if (_controlNetFramePaths.isNotEmpty) {
        controlNetPath = await _convertFramesToVideo();
      }

      // Clean up frame files
      for (final path in _controlNetFramePaths) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      _controlNetFramePaths.clear();

      return RecordingResult(
        sessionId: _sessionId!,
        rgbVideoPath: rgbDestPath,
        controlNetVideoPath: controlNetPath,
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Convert Frames to Video (Using FFmpeg)
  Future<String?> _convertFramesToVideo() async {
    // FFmpeg dependency failed (404), disabling video conversion temporarily.
    debugPrint('Video conversion skipped due to missing FFmpeg library.');
    return null;
    /*
    if (_controlNetFramePaths.isEmpty || _tempDir == null) return null;

    try {
      final outputPath = '${_tempDir!.path}/controlnet_video.mp4';
      // ... (Rest of the logic commented out)
    } catch (e) {
      return null;
    }
    */
  }

  /// Cancel Recording
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _frameTimer?.cancel();

    try {
      await _cameraController?.stopVideoRecording();
    } catch (_) {}

    // Clean up temporary files
    if (_tempDir != null && await _tempDir!.exists()) {
      await _tempDir!.delete(recursive: true);
    }

    _controlNetFramePaths.clear();
  }

  /// Dispose Resources
  void dispose() {
    _frameTimer?.cancel();
    _controlNetFramePaths.clear();
  }
}

/// Recording Result
class RecordingResult {
  final String sessionId;
  final String rgbVideoPath;
  final String? controlNetVideoPath;

  RecordingResult({
    required this.sessionId,
    required this.rgbVideoPath,
    this.controlNetVideoPath,
  });

  /// RGB File
  File get rgbFile => File(rgbVideoPath);

  /// ControlNet File
  File? get controlNetFile =>
      controlNetVideoPath != null ? File(controlNetVideoPath!) : null;
}
