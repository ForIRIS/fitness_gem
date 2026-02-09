import 'package:camera/camera.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/camera_utils.dart';
import '../utils/adaptive_one_euro_filter.dart';

class CameraManager {
  CameraController? _controller;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.stream,
    ),
  );

  bool _isDetecting = false;
  CameraDescription? _camera;

  final StreamController<List<Pose>> _poseStreamController =
      StreamController<List<Pose>>.broadcast();
  Stream<List<Pose>> get poseStream => _poseStreamController.stream;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint("No cameras found");
      return;
    }

    _camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      _camera!,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
  }

  void startPoseDetection() {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isStreamingImages) {
      return;
    }

    _controller!.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;

      _processImage(image).then((_) {
        _isDetecting = false;
      });
    });
  }

  final Map<PoseLandmarkType, AdaptiveOneEuroFilter> _filters = {};

  Future<void> _processImage(CameraImage image) async {
    final inputImage = CameraUtils.inputImageFromCameraImage(
      image,
      _controller!,
      _camera!,
    );
    if (inputImage == null) return;

    try {
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) {
        _poseStreamController.add([]);
        return;
      }

      final filteredPoses = _filterPoses(poses);
      _poseStreamController.add(filteredPoses);
    } catch (e) {
      debugPrint('Error detecting pose: $e');
    }
  }

  List<Pose> _filterPoses(List<Pose> poses) {
    if (poses.isEmpty || _controller == null) return [];

    final pose = poses.first;
    final Map<PoseLandmarkType, PoseLandmark> filteredLandmarks = {};
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Use previewSize for normalization.
    // landmarks from ML Kit are in image-space pixels.
    final double imgWidth = _controller!.value.previewSize!.width;
    final double imgHeight = _controller!.value.previewSize!.height;

    pose.landmarks.forEach((type, landmark) {
      if (!_filters.containsKey(type)) {
        _filters[type] = AdaptiveOneEuroFilter(
          profile: OneEuroProfile.controlled,
          adaptive: true,
        );
      }

      // 1. Normalize (0..1)
      final normalizedX = landmark.x / imgWidth;
      final normalizedY = landmark.y / imgHeight;

      // 2. Filter in normalized space
      final filteredNormalized = _filters[type]!.filter(t, [
        normalizedX,
        normalizedY,
      ]);

      // 3. Scale back to pixels
      filteredLandmarks[type] = PoseLandmark(
        type: type,
        x: filteredNormalized[0] * imgWidth,
        y: filteredNormalized[1] * imgHeight,
        z: landmark.z,
        likelihood: landmark.likelihood,
      );
    });

    return [Pose(landmarks: filteredLandmarks)];
  }

  Future<void> stopPoseDetection() async {
    if (_controller != null && _controller!.value.isStreamingImages) {
      await _controller!.stopImageStream();
    }
  }

  void dispose() {
    _poseStreamController.close();
    _controller?.dispose();
    _poseDetector.close();
  }
}
