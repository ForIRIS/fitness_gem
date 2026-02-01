import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import '../domain/entities/workout_curriculum.dart';
import '../services/workout_model_service.dart';
import '../domain/entities/workout_task.dart';
import '../services/cache_service.dart';
// Shimmer import removed
import 'loading_view.dart';
import 'camera_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/viewmodels/home_viewmodel.dart';
import '../theme/app_theme.dart';

class WorkoutDetailView extends ConsumerStatefulWidget {
  final WorkoutCurriculum curriculum;
  final int initialIndex;

  const WorkoutDetailView({
    super.key,
    required this.curriculum,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends ConsumerState<WorkoutDetailView> {
  late PageController _pageController;
  final _modelService = WorkoutModelService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialIndex,
      viewportFraction: 0.92,
    );

    // Preload model to reduce lag when starting workout
    _preloadModel();
  }

  Future<void> _preloadModel() async {
    // Fire and forget - just warm up the model loading
    try {
      await _modelService.loadSampleModel();
      debugPrint('Background model preloading completed');
    } catch (e) {
      debugPrint('Background model preloading failed: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskCount = widget.curriculum.workoutTasks.length;

    return Scaffold(
      backgroundColor: AppTheme.background, // Cloud Dancer
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section matching "Programs" layout
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Program', // Matching the screenshot title
                        style: GoogleFonts.outfit(
                          // Using Outfit for clean look
                          color: AppTheme.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: AppTheme.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pre-planned workout paired with audio guidance\nand expert coaching.', // Matching subtitle
                    style: GoogleFonts.outfit(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                itemCount: taskCount,
                itemBuilder: (context, index) {
                  final task = widget.curriculum.workoutTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: WorkoutDetailCard(
                      task: task,
                      index: index,
                      isActive: true, // Always active in list view
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E), // Dark background like HomeView
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _startWorkout,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                      ], // Purple gradient
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.startWorkout,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
          builder: (context) => CameraView(
            curriculum: widget.curriculum,
            userProfile: ref.read(homeViewModelProvider).userProfile,
          ),
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
          builder: (context) => CameraView(
            curriculum: widget.curriculum,
            userProfile: ref.read(homeViewModelProvider).userProfile,
          ),
        ),
      );
    }
  }
}

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

  // Removed unused _getImageProvider

  @override
  void initState() {
    super.initState();
    // Initialize video controller if URL is present - Keeping initialization but simplifying display
    if (widget.task.exampleVideoUrl.isNotEmpty) {
      _initializeVideo();
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
      debugPrint('Media URL refresh skipped - immutable entity limitation');
    }
  }

  // Removed unused PageController and _currentIndex

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if it's maintenance/stretch
    final bool isMaintenance =
        (widget.task.reps <= 1 && !widget.task.isCountable) ||
        widget.task.category.toLowerCase() == 'stretch';

    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB08CDD),
            Color(0xFF9670BF),
          ], // Soft Purple Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9670BF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Right-side Image (masked)
          Positioned(
            right: -20,
            bottom: 0,
            top: 20,
            width: 160,
            child: _buildSimpleVisualPreview(),
          ),

          // 2. Content Overlay (Text)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag (Pill shape)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isMaintenance
                        ? AppLocalizations.of(context)!.hold
                        : '${widget.task.adjustedSets} Sets',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                SizedBox(
                  width:
                      180, // Constrain width to avoid overlapping image too much
                  child: Text(
                    widget.task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),

                const Spacer(),

                // Subtext / Reps
                Text(
                  isMaintenance
                      ? 'Relax & Stretch'
                      : '${widget.task.adjustedReps} Reps per set',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 3. Circular Arrow Button
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                color: Colors.white.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simplified visual for the card
  Widget _buildSimpleVisualPreview() {
    if (_isVideoInitialized && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else if (widget.task.thumbnail.isNotEmpty) {
      return Image.network(
        widget.task.thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Center(
        child: Icon(Icons.fitness_center, color: Colors.white.withOpacity(0.3)),
      ),
    );
  }
}
