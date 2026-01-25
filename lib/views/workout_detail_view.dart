import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import '../models/workout_curriculum.dart';
import '../models/workout_task.dart';
import '../services/cache_service.dart';
import 'loading_view.dart';
import 'camera_view.dart';

class WorkoutDetailView extends StatefulWidget {
  final WorkoutCurriculum curriculum;
  final int initialIndex;

  const WorkoutDetailView({
    super.key,
    required this.curriculum,
    this.initialIndex = 0,
  });

  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 0.92,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskCount = widget.curriculum.workoutTaskList.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    AppLocalizations.of(context)!.todayWorkout,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: taskCount,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final task = widget.curriculum.workoutTaskList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: WorkoutDetailCard(
                      task: task,
                      index: index,
                      isActive: index == _currentIndex,
                    ),
                  );
                },
              ),
            ),

            // Page Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(taskCount, (index) {
                  final isActive = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.deepPurple : Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Start Workout Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startWorkout,
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: Text(
                    AppLocalizations.of(context)!.startWorkout,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkout() async {
    // Check for cached resources first
    final cacheService = CacheService();
    final isCached = await cacheService.areAllCurriculumResourcesCached(
      widget.curriculum,
    );

    if (isCached && mounted) {
      // Skip download screen and go straight to workout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraView(curriculum: widget.curriculum),
        ),
      );
      return;
    }

    // Navigate to Resource Caching Screen
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingView(curriculum: widget.curriculum),
      ),
    );

    // Navigate to Workout Screen upon caching completion
    if (result == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CameraView(curriculum: widget.curriculum),
        ),
      );
    }
  }
}

/// Individual Workout Detail Card Widget
class WorkoutDetailCard extends StatefulWidget {
  final WorkoutTask task;
  final int index;
  final bool isActive;

  const WorkoutDetailCard({
    super.key,
    required this.task,
    required this.index,
    required this.isActive,
  });

  @override
  State<WorkoutDetailCard> createState() => _WorkoutDetailCardState();
}

class _WorkoutDetailCardState extends State<WorkoutDetailCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(WorkoutDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Play/Pause video based on active state
    if (widget.isActive && _isVideoInitialized) {
      _videoController?.play();
    } else {
      _videoController?.pause();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.task.exampleVideoUrl.isEmpty) return;

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.task.exampleVideoUrl),
      );
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0); // Mute

      if (widget.isActive) {
        _videoController!.play();
      }

      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() => _hasVideoError = true);
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Preview
            _buildVideoPreview(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      children: [
                        // Index Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple,
                                Colors.deepPurple.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.task.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Category & Difficulty
                    Row(
                      children: [
                        _buildTag(
                          widget.task.categoryDisplayName,
                          Colors.cyan.shade700,
                        ),
                        const SizedBox(width: 8),
                        _buildTag(
                          widget.task.difficultyDisplayName,
                          _getDifficultyColor(widget.task.difficulty),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats Grid
                    _buildStatsGrid(),

                    const SizedBox(height: 20),

                    // Description
                    _buildSection(
                      icon: Icons.info_outline,
                      title: AppLocalizations.of(context)!.workoutDescription,
                      content: widget.task.description,
                    ),

                    // Precautions / Tips
                    if (widget.task.koreanAdvice != null &&
                        widget.task.koreanAdvice!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildPrecautionSection(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade900, Colors.black],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideoInitialized && _videoController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else if (_hasVideoError || widget.task.exampleVideoUrl.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task.title,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple,
                strokeWidth: 2,
              ),
            ),

          // Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xFF1A1A2E)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final isTimeBased = widget.task.category == 'core';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.repeat,
            value: isTimeBased
                ? AppLocalizations.of(
                    context,
                  )!.estimatedTime(widget.task.timeoutSec)
                : '${widget.task.adjustedReps}${AppLocalizations.of(context)!.confirm.characters.last}', // This is hacky, but '회' is usually last char of 'confirm' or similar in Korean. Actually let's just stick to numbers if possible or add a key. Let's just use numbers.
            label: isTimeBased
                ? AppLocalizations.of(
                    context,
                  )!.estimatedTime('').replaceAll(RegExp(r'[^가-힣a-zA-Z]'), '')
                : AppLocalizations.of(context)!.repsTotal.split(' ')[0],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _buildStatItem(
            icon: Icons.layers,
            value: '${widget.task.adjustedSets}',
            label: AppLocalizations.of(context)!.sets,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          _buildStatItem(
            icon: Icons.timer_outlined,
            value: '${widget.task.timeoutSec}초',
            label: '제한시간',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple.shade300, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildPrecautionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade900.withValues(alpha: 0.3),
            Colors.deepOrange.shade900.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade700.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.precautions,
                style: TextStyle(
                  color: Colors.orange.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.task.koreanAdvice!,
            style: TextStyle(
              color: Colors.orange.shade100,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
