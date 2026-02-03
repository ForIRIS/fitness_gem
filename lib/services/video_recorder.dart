import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Frame Data with Stability Score
class FrameData {
  final String path;
  final double stability;
  final int index;

  FrameData({required this.path, required this.stability, required this.index});
}

/// VideoRecorder - Dual-stream Video Recording Service
/// Records RGB video and ControlNet (Skeleton) video simultaneously
class VideoRecorder {
  // Configuration
  static const int targetFps = 15;
  static const int targetWidth = 640;
  static const int targetHeight = 360;
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

  // ControlNet Frame Capture
  final List<FrameData> _frameDataBuffer = [];
  int _frameCount = 0;
  Timer? _frameTimer;
  Pose? _currentPose;
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

      // Start ControlNet Frame Capture Timer
      _frameCount = 0;
      _frameDataBuffer.clear();
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
        _frameDataBuffer.add(
          FrameData(
            path: framePath,
            stability: _lastStability,
            index: _frameCount,
          ),
        );
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
  void updatePose(Pose? pose, {double stability = 1.0}) {
    _currentPose = pose;
    _lastStability = stability;
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
      final rawRgbPath = '${_tempDir!.path}/raw_rgb.mp4';
      await File(rgbXFile.path).copy(rawRgbPath);
      await File(rgbXFile.path).delete();

      // 2. Determine Best Highlight Window (Lowest Stability)
      final window = _findWorstStabilityWindow();
      final double startTimeSec = window.startIndex / targetFps;
      final double durationSec = window.length / targetFps;

      // 3. Trim RGB to Highlight Window
      final rgbDestPath = '${_tempDir!.path}/rgb_video.mp4';
      final trimSuccess = await _trimVideo(
        rawRgbPath,
        rgbDestPath,
        startTime: startTimeSec,
        duration: durationSec,
      );
      final finalRgbPath = trimSuccess ? rgbDestPath : rawRgbPath;

      // 4. Convert SELECTED Skeleton frames to video
      String? controlNetPath;
      if (window.frames.isNotEmpty) {
        controlNetPath = await _convertFramesToVideo(window.frames);
      }

      // 5. Clean up ALL temporary frame PNGs
      for (final frame in _frameDataBuffer) {
        try {
          final f = File(frame.path);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      _frameDataBuffer.clear();

      return RecordingResult(
        sessionId: _sessionId!,
        rgbVideoPath: finalRgbPath,
        controlNetVideoPath: controlNetPath,
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  /// Find 10-second window with lowest average stability
  _WindowResult _findWorstStabilityWindow() {
    if (_frameDataBuffer.isEmpty) {
      return _WindowResult(startIndex: 0, length: 0, frames: []);
    }

    final int n = _frameDataBuffer.length;
    final int winSize = maxHighlightFrames;

    // If session is shorter than 10s, return all
    if (n <= winSize) {
      return _WindowResult(
        startIndex: 0,
        length: n,
        frames: List.from(_frameDataBuffer),
      );
    }

    int bestStart = n - winSize; // Default to last 10s if no clear "winner"
    double minStabilitySum = double.infinity;

    // Sliding window for min stability
    double currentSum = 0.0;
    for (int i = 0; i < winSize; i++) {
      currentSum += _frameDataBuffer[i].stability;
    }

    minStabilitySum = currentSum;
    bestStart = 0;

    for (int i = 1; i <= n - winSize; i++) {
      currentSum =
          currentSum -
          _frameDataBuffer[i - 1].stability +
          _frameDataBuffer[i + winSize - 1].stability;
      if (currentSum < minStabilitySum) {
        minStabilitySum = currentSum;
        bestStart = i;
      }
    }

    final selectedFrames = _frameDataBuffer.sublist(
      bestStart,
      bestStart + winSize,
    );
    return _WindowResult(
      startIndex: bestStart,
      length: winSize,
      frames: selectedFrames,
    );
  }

  /// Trim Video to Highlight Window
  Future<bool> _trimVideo(
    String inputPath,
    String outputPath, {
    required double startTime,
    required double duration,
  }) async {
    try {
      // Use re-encoding for precise cuts if needed, or copy for speed
      // -ss before -i is faster. -t is duration.
      final command =
          '-ss ${startTime.toStringAsFixed(2)} -i $inputPath -t ${duration.toStringAsFixed(2)} -c copy -y $outputPath';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('Error trimming video: $e');
      return false;
    }
  }

  /// Convert PNG Frames to Mp4 Video using FFmpeg
  Future<String?> _convertFramesToVideo(List<FrameData> frames) async {
    if (frames.isEmpty || _tempDir == null) return null;

    try {
      final outputPath = '${_tempDir!.path}/controlnet_video.mp4';

      // We need to re-index frames to %05d for FFmpeg to read them sequentially
      // Copy selected frames to a temporary "stitch" folder
      final stitchDir = Directory('${_tempDir!.path}/stitch');
      if (await stitchDir.exists()) await stitchDir.delete(recursive: true);
      await stitchDir.create();

      for (int i = 0; i < frames.length; i++) {
        final destPath =
            '${stitchDir.path}/frame_${i.toString().padLeft(5, '0')}.png';
        await File(frames[i].path).copy(destPath);
      }

      // FFmpeg Command
      final command =
          '-framerate $targetFps -i ${stitchDir.path}/frame_%05d.png -vcodec libx264 -crf 25 -pix_fmt yuv420p -y $outputPath';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // Clean up stitch dir
      await stitchDir.delete(recursive: true);

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
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

    _frameDataBuffer.clear();
  }

  /// Dispose Timer
  void dispose() {
    _frameTimer?.cancel();
    _frameDataBuffer.clear();
  }
}

/// Internal helper for window result
class _WindowResult {
  final int startIndex;
  final int length;
  final List<FrameData> frames;
  _WindowResult({
    required this.startIndex,
    required this.length,
    required this.frames,
  });
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
