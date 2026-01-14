import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'dart:math';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  PosePainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        // We will assume landmark.x/y are already smoothed by the caller if needed
        canvas.drawCircle(
          _coordinateFor(landmark.x, landmark.y, size),
          4, // slightly larger for visibility
          paint,
        );
      });

      void paintLine(
        PoseLandmarkType type1,
        PoseLandmarkType type2,
        Paint paintType,
      ) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        final PoseLandmark joint2 = pose.landmarks[type2]!;
        canvas.drawLine(
          _coordinateFor(joint1.x, joint1.y, size),
          _coordinateFor(joint2.x, joint2.y, size),
          paintType,
        );
      }

      //Draw arms
      paintLine(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        leftPaint,
      );
      paintLine(
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
        leftPaint,
      );
      paintLine(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        rightPaint,
      );
      paintLine(
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
        rightPaint,
      );

      //Draw Body
      paintLine(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
        leftPaint,
      );
      paintLine(
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        rightPaint,
      );
      paintLine(
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        paint,
      );
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);

      //Draw Legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
        leftPaint,
      );
      paintLine(
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
        rightPaint,
      );
      paintLine(
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
        rightPaint,
      );
    }
  }

  // Implements BoxFit.cover logic manually
  Offset _coordinateFor(double x, double y, Size size) {
    // 1. Determine image dimensions based on rotation
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    // 2. Determine Scale
    final double imageWidth = isRotated
        ? absoluteImageSize.height
        : absoluteImageSize.width;
    final double imageHeight = isRotated
        ? absoluteImageSize.width
        : absoluteImageSize.height;

    final double scaleX = size.width / imageWidth;
    final double scaleY = size.height / imageHeight;
    final double scale = max(scaleX, scaleY);

    // 3. Calculate Offset to center the image
    final double scaledWidth = imageWidth * scale;
    final double scaledHeight = imageHeight * scale;
    final double offsetX = (size.width - scaledWidth) / 2;
    final double offsetY = (size.height - scaledHeight) / 2;

    // 4. Map coordinates
    double targetX = x * scale;
    double targetY = y * scale;

    if (cameraLensDirection == CameraLensDirection.front) {
      // Mirroring: Flip X axis relative to the image frame
      targetX = scaledWidth - targetX;
    }

    return Offset(targetX + offsetX, targetY + offsetY);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses;
  }
}
