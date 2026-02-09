import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

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

  /// Unzips an asset zip file to a local temporary directory and returns the path to the unzipped content.
  /// [assetPath] is the path to the zip asset (e.g., assets/models/model.zip)
  /// [targetDirName] is the expected directory name inside the zip (or where to extract)
  static Future<String> unzipAssetToTemp(
    String assetPath,
    String targetDirName,
  ) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final targetDir = Directory('${tempDir.path}/$targetDirName');

    // If already exists, might want to return cached, but for now overwrite to be safe or check hash
    if (await targetDir.exists()) {
      // Optional: return targetDir.path;
      // For dev/debugging, let's re-extract to ensure fresh model
      await targetDir.delete(recursive: true);
    }

    final archive = ZipDecoder().decodeBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        // Fix: Extract into the target directory, not just tempDir
        final outFile = File('${targetDir.path}/$filename');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
      } else {
        // Fix: Create directory inside target directory
        await Directory('${targetDir.path}/$filename').create(recursive: true);
      }
    }

    return targetDir.path;
  }
}
