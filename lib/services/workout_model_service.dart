import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/exercise_model_output.dart';
import '../utils/asset_utils.dart';
import 'package:path/path.dart' as p;
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

  Future<bool> loadLocalBundle(String bundleId) async {
    final assetPath = 'assets/bundles/$bundleId.zip';

    final isIOSTarget = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    try {
      // Step 1: Unzip the bundle zip to temp
      final unzippedPath = await AssetUtils.unzipAssetToTemp(
        assetPath,
        bundleId,
      );
      final dir = Directory(unzippedPath);

      if (isIOSTarget) {
        // iOS: The bundle zip contains "pose_model.mlpackage.zip" (a nested zip).
        // We need to find it and unzip it to get the actual .mlpackage directory.
        final entities = dir.listSync(recursive: true);

        // First, try to find pose_model.mlpackage.zip (nested zip)
        final innerZipEntity = entities.cast<FileSystemEntity?>().firstWhere(
          (e) => e != null && e.path.endsWith('pose_model.mlpackage.zip'),
          orElse: () => null,
        );

        if (innerZipEntity != null) {
          // Step 2: Unzip the inner mlpackage zip to a temp staging dir
          final stagingDir = '${dir.path}/_mlpackage_staging';
          await AssetUtils.unzipFileToDir(innerZipEntity.path, stagingDir);
          debugPrint("Extracted inner mlpackage zip to staging: $stagingDir");

          // Step 3: Determine the actual mlpackage path.
          // The zip may contain files at root (flat) or inside a nested folder.
          final stagingDirObj = Directory(stagingDir);
          final manifestFile = File('$stagingDir/Manifest.json');

          String actualModelParentDir;
          if (await manifestFile.exists()) {
            // Flat structure: Manifest.json is at staging root.
            // Rename staging dir to pose_model.mlpackage
            final targetDir = '${dir.path}/pose_model.mlpackage';
            await stagingDirObj.rename(targetDir);
            actualModelParentDir = dir.path;
            debugPrint(
              "Flat mlpackage structure detected. Model at: $targetDir",
            );
          } else {
            // Nested structure: look for Manifest.json inside a subdirectory
            final nestedManifest = File(
              '$stagingDir/pose_model.mlpackage/Manifest.json',
            );
            if (await nestedManifest.exists()) {
              // The actual mlpackage dir is inside staging
              actualModelParentDir = stagingDir;
              debugPrint(
                "Nested mlpackage structure detected. Model at: $stagingDir/pose_model.mlpackage",
              );
            } else {
              // Last resort: find Manifest.json anywhere
              final allEntities = stagingDirObj.listSync(recursive: true);
              final manifestEntity = allEntities
                  .cast<FileSystemEntity?>()
                  .firstWhere(
                    (e) => e != null && e.path.endsWith('Manifest.json'),
                    orElse: () => null,
                  );
              if (manifestEntity != null) {
                // Parent of Manifest.json is the mlpackage dir
                final mlpkgDir = p.dirname(manifestEntity.path);
                actualModelParentDir = p.dirname(mlpkgDir);
                debugPrint("Found Manifest.json at: ${manifestEntity.path}");
              } else {
                debugPrint(
                  "Manifest.json not found after extracting inner zip",
                );
                return false;
              }
            }
          }

          // loadModel appends /pose_model.mlpackage, so pass the parent
          return await loadModel(actualModelParentDir);
        }

        // Fallback: maybe it's already a directory (older bundle format)
        final mlpackageDirEntity = entities
            .cast<FileSystemEntity?>()
            .firstWhere(
              (e) =>
                  e != null &&
                  e is Directory &&
                  e.path.endsWith('pose_model.mlpackage'),
              orElse: () => null,
            );

        if (mlpackageDirEntity != null) {
          return await loadModel(p.dirname(mlpackageDirEntity.path));
        }

        debugPrint(
          "Neither pose_model.mlpackage.zip nor pose_model.mlpackage found in bundle",
        );
        return false;
      } else {
        // Android: Look for .onnx file
        final entities = dir.listSync(recursive: true);
        final modelEntity = entities.cast<FileSystemEntity?>().firstWhere(
          (e) => e != null && e.path.endsWith('pose_model.onnx'),
          orElse: () => null,
        );
        if (modelEntity == null) {
          debugPrint("ONNX model not found in zip");
          return false;
        }
        return await loadModel(p.dirname(modelEntity.path));
      }
    } catch (e) {
      debugPrint("Failed to load local bundle $bundleId: $e");
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
