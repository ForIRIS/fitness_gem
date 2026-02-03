import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

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
  // ignore: unused_field
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

  /// Generate Skeleton Image (Black Background + Multi-color Skeleton)
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

      // Define Connections with Color Coding for better Gemini Vision
      final connections = [
        // Face (White)
        {
          'pair': [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
          'color': const ui.Color(0xFFFFFFFF),
        },
        {
          'pair': [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
          'color': const ui.Color(0xFFFFFFFF),
        },
        {
          'pair': [PoseLandmarkType.nose, PoseLandmarkType.rightEye],
          'color': const ui.Color(0xFFFFFFFF),
        },
        {
          'pair': [PoseLandmarkType.rightEye, PoseLandmarkType.rightEar],
          'color': const ui.Color(0xFFFFFFFF),
        },

        // Torso/Hips (Yellow)
        {
          'pair': [
            PoseLandmarkType.leftShoulder,
            PoseLandmarkType.rightShoulder,
          ],
          'color': const ui.Color(0xFFFFFF00),
        },
        {
          'pair': [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
          'color': const ui.Color(0xFFFFFF00),
        },
        {
          'pair': [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
          'color': const ui.Color(0xFFFFFF00),
        },
        {
          'pair': [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
          'color': const ui.Color(0xFFFFFF00),
        },

        // Left Side (Blue/Cyan - Cold colors)
        {
          'pair': [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
          'color': const ui.Color(0xFF2196F3),
        },
        {
          'pair': [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
          'color': const ui.Color(0xFF2196F3),
        },
        {
          'pair': [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
          'color': const ui.Color(0xFF2196F3),
        },
        {
          'pair': [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
          'color': const ui.Color(0xFF2196F3),
        },

        // Right Side (Red/Orange - Hot colors)
        {
          'pair': [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
          'color': const ui.Color(0xFFF44336),
        },
        {
          'pair': [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
          'color': const ui.Color(0xFFF44336),
        },
        {
          'pair': [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
          'color': const ui.Color(0xFFF44336),
        },
        {
          'pair': [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
          'color': const ui.Color(0xFFF44336),
        },
      ];

      // Connection Drawing Settings
      final previewHeight = _cameraController!.value.previewSize!.height;
      final previewWidth = _cameraController!.value.previewSize!.width;

      // Draw Connections
      for (final connection in connections) {
        final pair = connection['pair'] as List<PoseLandmarkType>;
        final color = connection['color'] as ui.Color;

        final p1 = pose.landmarks[pair[0]];
        final p2 = pose.landmarks[pair[1]];

        if (p1 != null && p2 != null) {
          final paint = Paint()
            ..color = color
            ..strokeWidth =
                5.0 // Bold lines for Gemini
            ..style = PaintingStyle.stroke;

          final x1 = p1.x / previewHeight * targetWidth;
          final y1 = p1.y / previewWidth * targetHeight;
          final x2 = p2.x / previewHeight * targetWidth;
          final y2 = p2.y / previewWidth * targetHeight;

          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        }
      }

      // Draw Joint Points (Green - High Visibility)
      final pointPaint = Paint()
        ..color = const ui.Color(0xFF00FF00)
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round;

      for (final landmark in pose.landmarks.values) {
        final x = landmark.x / previewHeight * targetWidth;
        final y = landmark.y / previewWidth * targetHeight;
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

  /// Update Current Pose (Called every frame from CameraView)
  void updatePose(Pose? pose) {
    _currentPose = pose;
    if (onPoseUpdate != null) onPoseUpdate!(pose);
  }

  /// Stop Recording and Return File Result
  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;
    _frameTimer?.cancel();

    try {
      // 1. Stop RGB Recording
      final rgbXFile = await _cameraController!.stopVideoRecording();

      // Move RGB file to session directory
      final rgbDestPath = '${_tempDir!.path}/rgb_video.mp4';
      await File(rgbXFile.path).copy(rgbDestPath);
      await File(rgbXFile.path).delete();

      // 2. Convert ControlNet frames to video
      String? controlNetPath;
      if (_controlNetFramePaths.isNotEmpty) {
        controlNetPath = await _convertFramesToVideo();
      }

      // 3. Clean up temporary frame PNGs
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

  /// Convert PNG Frames to Mp4 Video using FFmpeg
  Future<String?> _convertFramesToVideo() async {
    if (_controlNetFramePaths.isEmpty || _tempDir == null) return null;

    try {
      final outputPath = '${_tempDir!.path}/controlnet_video.mp4';

      // FFmpeg Command for High Compatibility
      final command =
          '-framerate $targetFps -i ${_tempDir!.path}/frame_%05d.png -vcodec libx264 -crf 25 -pix_fmt yuv420p -y $outputPath';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        debugPrint('ControlNet video generated: $outputPath');
        return outputPath;
      } else {
        debugPrint('FFmpeg execution failed: ${await session.getOutput()}');
        return null;
      }
    } catch (e) {
      debugPrint('Error in _convertFramesToVideo: $e');
      return null;
    }
  }

  /// Cancel Recording and Clean up
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _frameTimer?.cancel();

    try {
      await _cameraController?.stopVideoRecording();
    } catch (_) {}

    if (_tempDir != null && await _tempDir!.exists()) {
      await _tempDir!.delete(recursive: true);
    }

    _controlNetFramePaths.clear();
  }

  /// Dispose Timer
  void dispose() {
    _frameTimer?.cancel();
    _controlNetFramePaths.clear();
  }
}

/// Recording Result Data Class
class RecordingResult {
  final String sessionId;
  final String rgbVideoPath;
  final String? controlNetVideoPath;

  RecordingResult({
    required this.sessionId,
    required this.rgbVideoPath,
    this.controlNetVideoPath,
  });

  File get rgbFile => File(rgbVideoPath);
  File? get controlNetFile =>
      controlNetVideoPath != null ? File(controlNetVideoPath!) : null;
}
