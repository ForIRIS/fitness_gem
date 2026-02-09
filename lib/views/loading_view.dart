import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../domain/entities/workout_curriculum.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';

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

    // Calculate total resources (excluding empty URLs)
    int total = 0;
    for (final _ in widget.curriculum.workoutTasks) {
      total += 4;
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
        widget.curriculum.workoutTasks,
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
          _statusMessage = AppLocalizations.of(
            context,
          )!.downloadFailed(e.toString());
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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation or Lottie could go here. For now, themed icon.
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:
                      (_isComplete
                              ? AppTheme.success
                              : _hasError
                              ? AppTheme.error
                              : AppTheme.primary)
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isComplete
                      ? Icons.check_circle_rounded
                      : _hasError
                      ? Icons.error_rounded
                      : Icons.downloading_rounded,
                  size: 80,
                  color: _isComplete
                      ? AppTheme.success
                      : _hasError
                      ? AppTheme.error
                      : AppTheme.primary,
                ),
              ),

              const SizedBox(height: 48),

              // Status Message
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Current downloading item
              AnimatedOpacity(
                opacity: (_currentItem.isNotEmpty && !_isComplete && !_hasError)
                    ? 1.0
                    : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _currentItem,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 40),

              // Progress Bar
              if (_totalCount > 0 && !_isComplete && !_hasError)
                Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 12,
                          width:
                              MediaQuery.of(context).size.width *
                              32 *
                              2 /
                              MediaQuery.of(context).size.width, // Calculation
                          // Better to use LayoutBuilder or simple fraction
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_completedCount / _totalCount).clamp(
                              0.0,
                              1.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$_completedCount / $_totalCount',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

              // Indeterminate Loading (Initial state)
              if (_totalCount == 0 && !_isComplete && !_hasError)
                const CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 3,
                ),

              const Spacer(),

              // Retry Button on Error
              if (_hasError)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(AppLocalizations.of(context)!.retry),
                  ),
                ),

              const SizedBox(height: 16),

              // Cancel Button
              if (!_isComplete)
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
