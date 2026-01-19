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

/// VideoRecorder - Dual-stream 영상 녹화 서비스
/// RGB 영상과 ControlNet(스켈레톤) 영상을 동시에 녹화
class VideoRecorder {
  // 설정
  static const int targetFps = 15;
  static const int targetWidth = 640;
  static const int targetHeight = 480;

  // 상태
  bool _isRecording = false;
  String? _sessionId;
  Directory? _tempDir;

  // RGB 녹화
  CameraController? _cameraController;
  String? _rgbVideoPath;

  // ControlNet 프레임 캡처
  final List<String> _controlNetFramePaths = [];
  int _frameCount = 0;
  Timer? _frameTimer;
  Pose? _currentPose;

  // 콜백
  void Function(Pose?)? onPoseUpdate;

  bool get isRecording => _isRecording;
  String? get sessionId => _sessionId;

  /// 녹화 시작
  Future<bool> startRecording(CameraController cameraController) async {
    if (_isRecording) return false;

    try {
      _cameraController = cameraController;
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // 임시 디렉토리 생성
      final appDir = await getApplicationDocumentsDirectory();
      _tempDir = Directory('${appDir.path}/recordings/$_sessionId');
      if (!await _tempDir!.exists()) {
        await _tempDir!.create(recursive: true);
      }

      // RGB 녹화 시작
      _rgbVideoPath = '${_tempDir!.path}/rgb_video.mp4';
      await _cameraController!.startVideoRecording();

      // ControlNet 프레임 캡처 타이머 시작
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

  /// ControlNet 프레임 캡처 시작
  void _startControlNetCapture() {
    // 15fps = 약 66ms 간격
    _frameTimer = Timer.periodic(
      Duration(milliseconds: (1000 / targetFps).round()),
      (_) => _captureControlNetFrame(),
    );
  }

  /// ControlNet 프레임 캡처
  Future<void> _captureControlNetFrame() async {
    if (!_isRecording || _currentPose == null || _tempDir == null) return;

    try {
      final framePath =
          '${_tempDir!.path}/frame_${_frameCount.toString().padLeft(5, '0')}.png';

      // 스켈레톤 이미지 생성
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

  /// 스켈레톤 이미지 생성 (검정 배경 + 흰색 스켈레톤)
  Future<Uint8List?> _generateSkeletonImage(Pose pose) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 검정 배경
      final bgPaint = Paint()..color = const ui.Color(0xFF000000);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        bgPaint,
      );

      // 스켈레톤 그리기
      final paint = Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      final pointPaint = Paint()
        ..color = const ui.Color(0xFF00FF00)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round;

      // 연결선 정의
      final connections = [
        // 얼굴
        [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
        [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
        [PoseLandmarkType.nose, PoseLandmarkType.rightEye],
        [PoseLandmarkType.rightEye, PoseLandmarkType.rightEar],
        // 몸통
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
        [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
        // 왼팔
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
        // 오른팔
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
        // 왼다리
        [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
        [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
        // 오른다리
        [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
        [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      ];

      // 연결선 그리기
      for (final connection in connections) {
        final p1 = pose.landmarks[connection[0]];
        final p2 = pose.landmarks[connection[1]];

        if (p1 != null && p2 != null) {
          // 좌표 정규화 (카메라 해상도 → 출력 해상도)
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

      // 관절 포인트 그리기
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

      // 이미지로 변환
      final picture = recorder.endRecording();
      final image = await picture.toImage(targetWidth, targetHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating skeleton image: $e');
      return null;
    }
  }

  /// 현재 포즈 업데이트 (매 프레임 호출)
  void updatePose(Pose? pose) {
    _currentPose = pose;
  }

  /// 녹화 중지 및 파일 반환
  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;
    _frameTimer?.cancel();

    try {
      // RGB 녹화 중지
      final rgbFile = await _cameraController!.stopVideoRecording();

      // RGB 파일을 원하는 위치로 이동
      final rgbDestPath = '${_tempDir!.path}/rgb_video.mp4';
      await File(rgbFile.path).copy(rgbDestPath);
      await File(rgbFile.path).delete();

      // ControlNet 프레임들을 영상으로 변환
      String? controlNetPath;
      if (_controlNetFramePaths.isNotEmpty) {
        controlNetPath = await _convertFramesToVideo();
      }

      // 프레임 파일들 정리
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

  /// 프레임을 비디오로 변환 (FFmpeg 사용)
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

  /// 녹화 취소
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _frameTimer?.cancel();

    try {
      await _cameraController?.stopVideoRecording();
    } catch (_) {}

    // 임시 파일들 정리
    if (_tempDir != null && await _tempDir!.exists()) {
      await _tempDir!.delete(recursive: true);
    }

    _controlNetFramePaths.clear();
  }

  /// 리소스 해제
  void dispose() {
    _frameTimer?.cancel();
    _controlNetFramePaths.clear();
  }
}

/// 녹화 결과
class RecordingResult {
  final String sessionId;
  final String rgbVideoPath;
  final String? controlNetVideoPath;

  RecordingResult({
    required this.sessionId,
    required this.rgbVideoPath,
    this.controlNetVideoPath,
  });

  /// RGB 파일
  File get rgbFile => File(rgbVideoPath);

  /// ControlNet 파일
  File? get controlNetFile =>
      controlNetVideoPath != null ? File(controlNetVideoPath!) : null;
}
