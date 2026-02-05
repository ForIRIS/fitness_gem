import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/exercise_model_output.dart';
import '../utils/asset_utils.dart';
import 'package:path/path.dart' as p;

class WorkoutModelService {
  static const MethodChannel _channel = MethodChannel(
    'com.antigravity.fitness_gem/model_runner',
  );

  /// Load the model from the local file system
  /// [modelPath] should be the absolute path to the .mlpackage (iOS) or .onnx (Android) file
  Future<bool> loadModel(String modelPath) async {
    try {
      String assetPath;
      final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      if (isIOS) {
        assetPath = '$modelPath/pose_model.mlpackage';
      } else {
        assetPath = '$modelPath/pose_model.onnx';
      }

      final bool result = await _channel.invokeMethod('loadModel', {
        'modelPath': assetPath,
      });

      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to load model: '${e.message}'.");
      return false;
    }
  }

  /// Load the model from assets (extracts to temp file first)
  Future<bool> loadModelFromAsset(String assetPath) async {
    try {
      final localPath = await AssetUtils.getAssetPath(assetPath);
      return await loadModel(localPath);
    } catch (e) {
      debugPrint("Failed to load model from asset: $e");
      return false;
    }
  }

  /// Load the sample model based on platform
  Future<bool> loadSampleModel() async {
    const basePath = 'assets/models/31c7abde-ede2-4647-b366-4cfb9bf55bbe';

    final isIOSTarget = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (isIOSTarget) {
      try {
        // Unzip the .mlpackage.zip to temp directory
        final unzippedPath = await AssetUtils.unzipAssetToTemp(
          '$basePath/pose_model.mlpackage.zip',
          'pose_model.mlpackage',
        );
        final tempDir = p.dirname(unzippedPath);
        return await loadModel(tempDir);
      } catch (e) {
        debugPrint("Failed to load iOS model: $e");
        return false;
      }
    } else {
      const assetPath = '$basePath/pose_model.onnx';
      return await loadModelFromAsset(assetPath);
    }
  }

  /// Load the baseline assessment model (Air Squat)
  Future<bool> loadBaselineModel() async {
    const basePath = 'assets/models/air_squat';

    final isIOSTarget = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (isIOSTarget) {
      try {
        // Unzip the .mlpackage.zip to temp directory
        final unzippedPath = await AssetUtils.unzipAssetToTemp(
          '$basePath/pose_model.mlpackage.zip',
          'pose_model.mlpackage',
        );

        // Pass the parent directory of the .mlpackage
        final tempDir = p.dirname(unzippedPath);
        return await loadModel(tempDir);
      } catch (e) {
        debugPrint("Failed to load iOS baseline model: $e");
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
      debugPrint("Failed to run inference: '${e.message}'.");
    }
    return null;
  }

  /// Dispose the model resources on the native side
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } on PlatformException catch (e) {
      debugPrint("Failed to dispose model: '${e.message}'.");
    }
  }
}
