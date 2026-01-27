import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/exercise_config.dart';

class WorkoutModelService {
  static const MethodChannel _channel = MethodChannel(
    'com.antigravity.fitness_gem/model_runner',
  );

  /// Load the model from the local file system
  /// [modelPath] should be the absolute path to the .mlpackage (iOS) or .onnx (Android) file
  Future<bool> loadModel(String modelPath) async {
    try {
      final bool result = await _channel.invokeMethod('loadModel', {
        'modelPath': modelPath,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to load model: '${e.message}'.");
      return false;
    }
  }

  /// Run inference on a sequence of poses
  /// [poseSequence] is a 3D list: [30 frames][33 joints][3 coordinates x,y,z]
  /// Note: The input shape of the model is [1, 30, 33, 3]
  Future<ExerciseModelOutput?> runInference(
    List<List<List<double>>> poseSequence,
  ) async {
    try {
      // Flatten the 3D list to a 1D list for efficient transfer
      final List<double> flattened = [];
      for (final frame in poseSequence) {
        for (final joint in frame) {
          flattened.addAll(joint);
        }
      }

      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'runInference',
        {'input': Float32List.fromList(flattened)},
      );

      if (result != null) {
        return ExerciseModelOutput.fromMap(Map<String, dynamic>.from(result));
      }
    } on PlatformException catch (e) {
      print("Failed to run inference: '${e.message}'.");
    }
    return null;
  }

  /// Dispose the model resources on the native side
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } on PlatformException catch (e) {
      print("Failed to dispose model: '${e.message}'.");
    }
  }
}
