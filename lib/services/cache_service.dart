import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import '../domain/entities/workout_curriculum.dart';
import '../domain/entities/workout_task.dart';
import 'firebase_service.dart';

/// CacheService - Resource caching service
/// Download and local storage of guide videos, images, and audio
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Directory? _cacheDir;

  /// Initialize cache directory
  Future<Directory> get cacheDirectory async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/fitness_gem_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  /// Extract filename from URL
  String _getFileName(String url) {
    if (url.startsWith('assets/')) return url.split('/').last;
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return url.hashCode.toString();
  }

  /// Check if file exists in cache
  Future<bool> isCached(String url) async {
    if (url.isEmpty || url.startsWith('assets/'))
      return true; // No caching needed for empty or assets
    final file = await _getCacheFile(url);
    return file.existsSync();
  }

  /// Get cached file path
  Future<File> _getCacheFile(String url) async {
    final dir = await cacheDirectory;
    final fileName = _getFileName(url);
    return File('${dir.path}/$fileName');
  }

  /// Return cached file path (null if not exists)
  Future<String?> getCachedPath(String url) async {
    if (url.isEmpty) return null;
    final file = await _getCacheFile(url);
    if (file.existsSync()) {
      return file.path;
    }
    return null;
  }

  /// Download and cache file from URL
  Future<String?> downloadAndCache(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    if (url.isEmpty || url.startsWith('assets/')) return null;

    // Return immediately if already cached
    final existingPath = await getCachedPath(url);
    if (existingPath != null) {
      onProgress?.call(1.0);
      return existingPath;
    }

    try {
      final file = await _getCacheFile(url);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        onProgress?.call(1.0);
        return file.path;
      } else {
        debugPrint('Download failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  /// Unzip a file to the same directory
  Future<void> _unzipFile(File zipFile) async {
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File('${zipFile.parent.path}/$filename');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          final outDir = Directory('${zipFile.parent.path}/$filename');
          await outDir.create(recursive: true);
        }
      }
      // Optional: Delete the zip file after extraction
      // await zipFile.delete();
      debugPrint('Unzipped: ${zipFile.path}');
    } catch (e) {
      debugPrint('Unzip error for ${zipFile.path}: $e');
    }
  }

  /// Batch download multiple URLs
  Future<Map<String, String?>> downloadMultiple(
    List<String> urls, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <String, String?>{};
    int completed = 0;

    for (final url in urls) {
      if (url.isNotEmpty) {
        results[url] = await downloadAndCache(url);
      }
      completed++;
      onProgress?.call(completed, urls.length);
    }

    return results;
  }

  /// Cache all resources needed for a curriculum
  Future<bool> cacheWorkoutResources(
    List<WorkoutTask> tasks, {
    void Function(int completed, int total, String currentItem)? onProgress,
  }) async {
    // 1. If URLs are empty, fetch them via Cloud Functions
    List<WorkoutTask> currentTasks = tasks;
    final tasksToFetch = tasks.where((t) => t.exampleVideoUrl.isEmpty).toList();
    if (tasksToFetch.isNotEmpty) {
      onProgress?.call(0, 1, 'Fetching URLs...');
      currentTasks = await FirebaseService().requestTaskUrls(tasks);
    }

    final allUrls = <String>[];

    for (final task in currentTasks) {
      // Skip assets as they are handled by the app directly (e.g., VideoPlayer.asset)
      if (task.exampleVideoUrl.isNotEmpty &&
          !task.exampleVideoUrl.startsWith('assets/')) {
        allUrls.add(task.exampleVideoUrl);
      }
      if (task.readyPoseImageUrl.isNotEmpty &&
          !task.readyPoseImageUrl.startsWith('assets/')) {
        allUrls.add(task.readyPoseImageUrl);
      }
      if (task.guideAudioUrl.isNotEmpty &&
          !task.guideAudioUrl.startsWith('assets/')) {
        allUrls.add(task.guideAudioUrl);
      }
      if (task.configureUrl.isNotEmpty &&
          !task.configureUrl.startsWith('assets/')) {
        allUrls.add(task.configureUrl);
      }
      if (task.coremlUrl.isNotEmpty && !task.coremlUrl.startsWith('assets/')) {
        allUrls.add(task.coremlUrl);
      }
      if (task.onnxUrl.isNotEmpty) {
        allUrls.add(task.onnxUrl);
      }
    }

    int completed = 0;
    for (final url in allUrls) {
      final fileName = _getFileName(url);
      onProgress?.call(completed, allUrls.length, fileName);

      final cachedPath = await downloadAndCache(url);

      // If Zip file, unzip it
      if (cachedPath != null && url.toLowerCase().contains('.zip')) {
        onProgress?.call(completed, allUrls.length, 'Unzipping $fileName...');
        await _unzipFile(File(cachedPath));
      }

      completed++;
    }

    onProgress?.call(allUrls.length, allUrls.length, 'Complete');
    return true;
  }

  /// Check if all curriculum resources are already cached
  Future<bool> areAllCurriculumResourcesCached(
    WorkoutCurriculum curriculum,
  ) async {
    for (final task in curriculum.workoutTasks) {
      if (!await isCached(task.exampleVideoUrl) &&
          task.exampleVideoUrl.isNotEmpty) {
        return false;
      }
      if (!await isCached(task.readyPoseImageUrl) &&
          task.readyPoseImageUrl.isNotEmpty) {
        return false;
      }
      if (!await isCached(task.guideAudioUrl) &&
          task.guideAudioUrl.isNotEmpty) {
        return false;
      }
      if (!await isCached(task.configureUrl) && task.configureUrl.isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Check if all resources for a specific exercise are cached
  Future<bool> isTaskCached(WorkoutTask task) async {
    if (!await isCached(task.exampleVideoUrl) &&
        task.exampleVideoUrl.isNotEmpty) {
      return false;
    }
    if (!await isCached(task.readyPoseImageUrl) &&
        task.readyPoseImageUrl.isNotEmpty) {
      return false;
    }
    if (!await isCached(task.guideAudioUrl) && task.guideAudioUrl.isNotEmpty) {
      return false;
    }
    if (!await isCached(task.configureUrl) && task.configureUrl.isNotEmpty) {
      return false;
    }
    return true;
  }

  /// Calculate cache size (bytes)
  Future<int> getCacheSize() async {
    final dir = await cacheDirectory;
    int size = 0;

    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    }

    return size;
  }

  /// Clear all cache
  Future<void> clearCache() async {
    final dir = await cacheDirectory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }

  /// Delete files older than 7 days
  Future<void> cleanOldFiles() async {
    final dir = await cacheDirectory;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(sevenDaysAgo)) {
            await entity.delete();
          }
        }
      }
    }
  }
}

/// Collection of workout resource URLs
class WorkoutResourceUrls {
  final String exampleVideoUrl;
  final String readyPoseImageUrl;
  final String guideAudioUrl;
  final String configureUrl;

  WorkoutResourceUrls({
    required this.exampleVideoUrl,
    required this.readyPoseImageUrl,
    required this.guideAudioUrl,
    required this.configureUrl,
  });
}
