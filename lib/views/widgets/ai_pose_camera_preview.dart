import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../services/camera_manager.dart';
import '../../utils/pose_painter.dart';

class AIPoseCameraPreview extends StatelessWidget {
  final CameraManager cameraManager;
  final BoxFit fit;

  const AIPoseCameraPreview({
    super.key,
    required this.cameraManager,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraManager.isInitialized || cameraManager.controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white24),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: fit,
          child: SizedBox(
            width: cameraManager.controller!.value.previewSize!.height,
            height: cameraManager.controller!.value.previewSize!.width,
            child: CameraPreview(cameraManager.controller!),
          ),
        ),
        StreamBuilder<List<Pose>>(
          stream: cameraManager.poseStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox();
            }
            return Transform.scale(
              scaleX: -1,
              alignment: Alignment.center,
              child: CustomPaint(
                painter: PosePainter(
                  snapshot.data!,
                  cameraManager.controller!.value.previewSize!,
                  Platform.isAndroid
                      ? InputImageRotation.rotation270deg
                      : InputImageRotation.rotation90deg,
                  CameraLensDirection.front,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
