import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/exercise_model_output.dart';
import '../utils/asset_utils.dart';
import 'dart:io';

class WorkoutModelService {
  static const MethodChannel _channel = MethodChannel(
    'com.antigravity.fitness_gem/model_runner',
  );

  /// Load the model from the local file system
  /// [modelPath] should be the absolute path to the .mlpackage (iOS) or .onnx (Android) file
  Future<bool> loadModel(String modelPath) async {
    try {
      String assetPath;
      if (Platform.isIOS) {
        assetPath = '$modelPath/pose_model.mlpackage';
      } else {
        assetPath = '$modelPath/pose_model.onnx';
      }

      final bool result = await _channel.invokeMethod('loadModel', {
        'modelPath': assetPath,
      });

      return result;
    } on PlatformException catch (e) {
      print("Failed to load model: '${e.message}'.");
      return false;
    }
  }

  /// Load the model from assets (extracts to temp file first)
  Future<bool> loadModelFromAsset(String assetPath) async {
    try {
      final localPath = await AssetUtils.getAssetPath(assetPath);
      return await loadModel(localPath);
    } catch (e) {
      print("Failed to load model from asset: $e");
      return false;
    }
  }

  /// Load the sample model based on platform
  Future<bool> loadSampleModel() async {
    const basePath = 'assets/models/31c7abde-ede2-4647-b366-4cfb9bf55bbe';

    if (Platform.isIOS) {
      try {
        // Unzip the .mlpackage.zip to temp directory
        final unzippedPath = await AssetUtils.unzipAssetToTemp(
          '$basePath/pose_model.mlpackage.zip',
          'pose_model.mlpackage',
        );
        // The unzippedPath is the directory path containing the .mlpackage content
        // On iOS, we point to this directory
        // However, loadModel expects the PARENT directory of the model file if using the old logic,
        // let's check loadModel.
        // loadModel adds /pose_model.mlpackage to the path passed.
        // So if unzippedPath IS .../pose_model.mlpackage, we should pass the PARENT.
        // Actually, let's fix loadModel to be more flexible or adjust the call here.

        // Wait, loadModel(String modelPath) does: assetPath = '$modelPath/pose_model.mlpackage';
        // So if I pass unzippedPath which ends in pose_model.mlpackage,
        // loadModel will look for unzippedPath/pose_model.mlpackage, effectively .../pose_model.mlpackage/pose_model.mlpackage.
        // This is wrong if I unzipped IT as the directory.

        // Let's modify loadModel logic slightly or pass the parent.
        // AssetUtils.unzipAssetToTemp returns targetDir.path which is .../pose_model.mlpackage

        // So I should pass the parent of unzippedPath to loadModel?
        // Or better, reuse loadModel logic logic properly.

        // Let's look at loadModel again.
        // loadModel(String modelPath) -> uses $modelPath/pose_model.mlpackage.
        // So modelPath is expected to be the directory CONTAINING the mlpackage directory.

        final tempDir = Directory(unzippedPath).parent.path;
        return await loadModel(tempDir);
      } catch (e) {
        print("Failed to load iOS model: $e");
        return false;
      }
    } else {
      const assetPath = '$basePath/pose_model.onnx';
      return await loadModelFromAsset(assetPath);
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
