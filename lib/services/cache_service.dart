import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/workout_curriculum.dart';
import '../models/workout_task.dart';

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
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return url.hashCode.toString();
  }

  /// Check if file exists in cache
  Future<bool> isCached(String url) async {
    if (url.isEmpty) return true; // No caching needed for empty URLs
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
    if (url.isEmpty) return null;

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
    List<WorkoutResourceUrls> resources, {
    void Function(int completed, int total, String currentItem)? onProgress,
  }) async {
    final allUrls = <String>[];

    for (final resource in resources) {
      if (resource.exampleVideoUrl.isNotEmpty) {
        allUrls.add(resource.exampleVideoUrl);
      }
      if (resource.readyPoseImageUrl.isNotEmpty) {
        allUrls.add(resource.readyPoseImageUrl);
      }
      if (resource.guideAudioUrl.isNotEmpty) {
        allUrls.add(resource.guideAudioUrl);
      }
      if (resource.configureUrl.isNotEmpty) {
        allUrls.add(resource.configureUrl);
      }
    }

    int completed = 0;
    for (final url in allUrls) {
      final fileName = _getFileName(url);
      onProgress?.call(completed, allUrls.length, fileName);

      await downloadAndCache(url);
      completed++;
    }

    onProgress?.call(allUrls.length, allUrls.length, 'Complete');
    onProgress?.call(allUrls.length, allUrls.length, 'Complete');
    return true;
  }

  /// Check if all curriculum resources are already cached
  Future<bool> areAllCurriculumResourcesCached(
    WorkoutCurriculum curriculum,
  ) async {
    for (final task in curriculum.workoutTaskList) {
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
