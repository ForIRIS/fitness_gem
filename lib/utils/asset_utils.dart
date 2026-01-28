import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AssetUtils {
  /// Copies an asset file to a local temporary directory and returns the absolute path.
  /// This is necessary because native model loaders (CoreML/ONNX) require a file system path.
  static Future<String> getAssetPath(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);

    final tempDir = await getTemporaryDirectory();
    final fileName = p.basename(assetPath);
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );

    return file.path;
  }

  /// Copies all files in a directory asset to a local directory (recursive simulation)
  /// Note: Flutter assets don't support directory listing easily, so we usually
  /// call getAssetPath for specific known files.
}
