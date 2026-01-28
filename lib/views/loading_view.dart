import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../models/workout_curriculum.dart';
import '../services/cache_service.dart';

/// LoadingView - Resource Download Screen
class LoadingView extends StatefulWidget {
  final WorkoutCurriculum curriculum;

  const LoadingView({super.key, required this.curriculum});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> {
  String _statusMessage = '...';
  int _completedCount = 0;
  int _totalCount = 0;
  String _currentItem = '';
  bool _isComplete = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCaching();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_statusMessage == '...') {
      _statusMessage = AppLocalizations.of(context)!.preparing;
    }
  }

  Future<void> _startCaching() async {
    final cacheService = CacheService();

    // Create list of resources to cache
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

    // Calculate total resources (excluding empty URLs)
    int total = 0;
    for (final resource in resources) {
      if (resource.exampleVideoUrl.isNotEmpty) total++;
      if (resource.readyPoseImageUrl.isNotEmpty) total++;
      if (resource.guideAudioUrl.isNotEmpty) total++;
      if (resource.configureUrl.isNotEmpty) total++;
    }

    // If all URLs are empty (dummy data), complete immediately
    if (total == 0) {
      if (mounted) {
        setState(() {
          _statusMessage = AppLocalizations.of(context)!.ready;
          _isComplete = true;
        });
      }
      await Future.delayed(
        const Duration(milliseconds: 800),
      ); // Smooth transition
      if (mounted) {
        Navigator.pop(context, true);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _totalCount = total;
        _statusMessage = AppLocalizations.of(context)!.downloadingResources;
      });
    }

    final startTime = DateTime.now();

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

      // Ensure minimum display time (smoothness)
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 800) {
        await Future.delayed(
          Duration(milliseconds: 800 - elapsed.inMilliseconds),
        );
      }

      if (mounted) {
        setState(() {
          _statusMessage = AppLocalizations.of(context)!.downloadComplete;
          _isComplete = true;
        });
      }

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = AppLocalizations.of(context)!.downloadFailed(e);
          _hasError = true;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _statusMessage = AppLocalizations.of(context)!.preparing;
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
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/fitness_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.black),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
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

                  // Status Message
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

                  // Current downloading file
                  if (_currentItem.isNotEmpty && !_isComplete && !_hasError)
                    Text(
                      _currentItem,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Progress Bar
                  if (_totalCount > 0 && !_isComplete && !_hasError)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _completedCount / _totalCount,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
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

                  // Indeterminate Loading (When no URLs)
                  if (_totalCount == 0 && !_isComplete && !_hasError)
                    const CircularProgressIndicator(color: Colors.deepPurple),

                  const SizedBox(height: 32),

                  // Retry Button on Error
                  if (_hasError)
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),

                  // Cancel Button
                  if (!_isComplete)
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
