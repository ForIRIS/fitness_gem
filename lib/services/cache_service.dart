import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/workout_curriculum.dart';

/// CacheService - 리소스 캐싱 서비스
/// 가이드 영상, 이미지, 오디오 다운로드 및 로컬 저장
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Directory? _cacheDir;

  /// 캐시 디렉토리 초기화
  Future<Directory> get cacheDirectory async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/fitness_gem_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  /// URL에서 파일 이름 추출
  String _getFileName(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return url.hashCode.toString();
  }

  /// 파일이 캐시에 존재하는지 확인
  Future<bool> isCached(String url) async {
    if (url.isEmpty) return true; // 빈 URL은 캐시 불필요
    final file = await _getCacheFile(url);
    return file.existsSync();
  }

  /// 캐시된 파일 경로 가져오기
  Future<File> _getCacheFile(String url) async {
    final dir = await cacheDirectory;
    final fileName = _getFileName(url);
    return File('${dir.path}/$fileName');
  }

  /// 캐시된 파일 경로 반환 (없으면 null)
  Future<String?> getCachedPath(String url) async {
    if (url.isEmpty) return null;
    final file = await _getCacheFile(url);
    if (file.existsSync()) {
      return file.path;
    }
    return null;
  }

  /// URL에서 파일 다운로드 및 캐싱
  Future<String?> downloadAndCache(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    if (url.isEmpty) return null;

    // 이미 캐시되어 있으면 바로 반환
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

  /// 여러 URL 일괄 다운로드
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

  /// 커리큘럼에 필요한 모든 리소스 캐싱
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

    onProgress?.call(allUrls.length, allUrls.length, '완료');
    onProgress?.call(allUrls.length, allUrls.length, '완료');
    return true;
  }

  /// 모든 리소스가 이미 캐시되어 있는지 확인
  Future<bool> areAllCurriculumResourcesCached(
    WorkoutCurriculum curriculum,
  ) async {
    for (final task in curriculum.workoutTaskList) {
      if (!await isCached(task.exampleVideoUrl) &&
          task.exampleVideoUrl.isNotEmpty)
        return false;
      if (!await isCached(task.readyPoseImageUrl) &&
          task.readyPoseImageUrl.isNotEmpty)
        return false;
      if (!await isCached(task.guideAudioUrl) && task.guideAudioUrl.isNotEmpty)
        return false;
      if (!await isCached(task.configureUrl) && task.configureUrl.isNotEmpty)
        return false;
    }
    return true;
  }

  /// 캐시 크기 계산 (바이트)
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

  /// 캐시 전체 삭제
  Future<void> clearCache() async {
    final dir = await cacheDirectory;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }

  /// 7일 이상 된 파일 삭제
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

/// 운동 리소스 URL 모음
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
