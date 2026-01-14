import 'package:flutter/material.dart';
import '../models/workout_curriculum.dart';
import '../services/cache_service.dart';

/// LoadingView - 리소스 다운로드 화면
class LoadingView extends StatefulWidget {
  final WorkoutCurriculum curriculum;

  const LoadingView({super.key, required this.curriculum});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> {
  String _statusMessage = '준비 작업 중...';
  int _completedCount = 0;
  int _totalCount = 0;
  String _currentItem = '';
  bool _isComplete = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startCaching();
  }

  Future<void> _startCaching() async {
    final cacheService = CacheService();

    // 캐싱할 리소스 목록 생성
    final resources = <WorkoutResourceUrls>[];
    for (final task in widget.curriculum.workoutTaskList) {
      resources.add(
        WorkoutResourceUrls(
          exampleVideoUrl: task.exampleVideoUrl,
          readyPoseImageUrl: task.readyPoseImageUrl,
          guideAudioUrl: task.guideAudioUrl,
          configureUrl: task.configureUrl,
        ),
      );
    }

    // 총 리소스 수 계산 (빈 URL 제외)
    int total = 0;
    for (final resource in resources) {
      if (resource.exampleVideoUrl.isNotEmpty) total++;
      if (resource.readyPoseImageUrl.isNotEmpty) total++;
      if (resource.guideAudioUrl.isNotEmpty) total++;
      if (resource.configureUrl.isNotEmpty) total++;
    }

    // 더미 데이터라 URL이 모두 비어있으면 바로 완료
    if (total == 0) {
      setState(() {
        _statusMessage = '준비 완료!';
        _isComplete = true;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    setState(() {
      _totalCount = total;
      _statusMessage = '필요한 파일을 다운로드 중입니다...';
    });

    try {
      await cacheService.cacheWorkoutResources(
        resources,
        onProgress: (completed, totalItems, currentItem) {
          if (mounted) {
            setState(() {
              _completedCount = completed;
              _currentItem = currentItem;
            });
          }
        },
      );

      setState(() {
        _statusMessage = '완료되었습니다!';
        _isComplete = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _statusMessage = '다운로드 실패: $e';
        _hasError = true;
      });
    }
  }

  void _retry() {
    setState(() {
      _statusMessage = '준비 작업 중...';
      _completedCount = 0;
      _totalCount = 0;
      _currentItem = '';
      _isComplete = false;
      _hasError = false;
    });
    _startCaching();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘
              Icon(
                _isComplete
                    ? Icons.check_circle
                    : _hasError
                    ? Icons.error
                    : Icons.downloading,
                size: 80,
                color: _isComplete
                    ? Colors.green
                    : _hasError
                    ? Colors.red
                    : Colors.deepPurple,
              ),

              const SizedBox(height: 32),

              // 상태 메시지
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // 현재 다운로드 중인 파일
              if (_currentItem.isNotEmpty && !_isComplete && !_hasError)
                Text(
                  _currentItem,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),

              const SizedBox(height: 24),

              // 프로그레스 바
              if (_totalCount > 0 && !_isComplete && !_hasError)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _completedCount / _totalCount,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation(
                          Colors.deepPurple,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_completedCount / $_totalCount',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

              // 무한 로딩 (URL이 없는 경우)
              if (_totalCount == 0 && !_isComplete && !_hasError)
                const CircularProgressIndicator(color: Colors.deepPurple),

              const SizedBox(height: 32),

              // 에러 시 재시도 버튼
              if (_hasError)
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('재시도'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),

              // 취소 버튼
              if (!_isComplete)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    '취소',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
