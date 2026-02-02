import 'package:flutter/material.dart';
// app_localizations import removed if truly unused, but wait, it IS used in _startWorkout text.
// Let me double check if it's used.
// "AppLocalizations.of(context)!.startWorkout" is used in WorkoutActionButtons which was extracted.
// So yes, it IS unused in WorkoutDetailView now.
// google_fonts is also unused in WorkoutDetailView as Text styles are in sub-widgets.
import '../domain/entities/workout_curriculum.dart';
import '../services/workout_model_service.dart';
// workout_task import removed
import '../services/cache_service.dart';
import 'loading_view.dart';
import 'camera_view.dart';
// google_fonts import removed
// dart:ui import removed
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/viewmodels/home_viewmodel.dart';
import '../theme/app_theme.dart';
import 'ai_chat_view.dart';
import 'widgets/workout/workout_detail_card.dart';
import 'widgets/workout/workout_header.dart';
import 'widgets/workout/workout_action_buttons.dart';

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

  void _openAIChat() async {
    final viewModel = ref.read(homeViewModelProvider);
    final userProfile = viewModel.userProfile;

    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for profile to load')),
      );
      return;
    }

    // Capture context before async gap if needed, or check mounted after
    if (!mounted) return;

    final newCurriculum = await Navigator.push<WorkoutCurriculum>(
      context,
      MaterialPageRoute(builder: (_) => AIChatView(userProfile: userProfile)),
    );

    debugPrint('AIChatView returned curriculum: ${newCurriculum?.title}');

    if (newCurriculum != null && mounted) {
      // Update global state
      debugPrint('Updating global state with new curriculum...');
      await viewModel.updateTodayCurriculum(newCurriculum);

      if (!mounted) return; // Check again before using context

      // Replace current view with the new curriculum
      debugPrint('Replacing view with new curriculum...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutDetailView(curriculum: newCurriculum),
        ),
      );
    }
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
            // Header Section
            const WorkoutHeader(),

            // Content List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 100,
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
      floatingActionButton: WorkoutActionButtons(
        onStartWorkout: _startWorkout,
        onOpenAIChat: _openAIChat,
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

// WorkoutDetailCard moved to lib/views/widgets/workout/workout_detail_card.dart
