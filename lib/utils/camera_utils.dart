import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/services.dart';

class CameraUtils {
  static InputImage? inputImageFromCameraImage(
    CameraImage image,
    CameraController controller,
    CameraDescription camera,
  ) {
    final rotations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    final sensorOrientation = camera.sensorOrientation;
    var rotation = rotations[controller.value.deviceOrientation];
    if (rotation == null) return null;

    // logic to calculate rotation
    final rotationCompensation = (sensorOrientation - rotation + 360) % 360;

    // Mapping to InputImageRotation
    InputImageRotation? inputRotation;
    switch (rotationCompensation) {
      case 0:
        inputRotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        inputRotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        inputRotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        inputRotation = InputImageRotation.rotation270deg;
        break;
    }
    if (inputRotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: inputRotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  static Uint8List _concatenatePlanes(List<Plane> planes) {
    if (planes.length == 1) {
      return planes.first.bytes;
    }
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}
