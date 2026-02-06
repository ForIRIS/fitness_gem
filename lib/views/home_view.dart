import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/cache_service.dart';
import '../presentation/viewmodels/home_viewmodel.dart';
import 'camera_view.dart';
import 'settings_view.dart';
import 'ai_chat_view.dart';
import 'workout_detail_view.dart';
import 'featured_program_detail_view.dart';
import 'statistics_view.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../domain/entities/workout_curriculum.dart';
import '../widgets/glass_dialog.dart';
import 'widgets/home/home_header.dart';
import 'widgets/home/daily_stats_card.dart';
import 'widgets/home/category_chips.dart';
import 'widgets/home/featured_program_card.dart';
import 'widgets/home/home_shimmer_widgets.dart';
import 'widgets/home/tomorrow_workout_card.dart';

/// HomeView - Dashboard Screen (Refactored with Riverpod)
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  // Local UI state (not business logic)
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    // Load data using ViewModel
    Future.microtask(() {
      ref.read(homeViewModelProvider).loadData();
      _updateCacheStatus();
    });
  }

  Future<void> _updateCacheStatus() async {
    // Wait for curriculum to load
    await Future.delayed(const Duration(milliseconds: 500));
    final viewModel = ref.read(homeViewModelProvider);
    if (viewModel.todayCurriculum == null) return;

    final cacheService = CacheService();
    for (final task in viewModel.todayCurriculum!.workoutTasks) {
      final isCached = await cacheService.isTaskCached(task);
      if (mounted) {
        setState(() {
          _downloadProgress[task.id] = isCached ? 1.0 : 0.0;
        });
      }
    }
  }

  void _openStatistics() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StatisticsView()));
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
  }

  void _openAIChat() async {
    final viewModel = ref.read(homeViewModelProvider);
    if (viewModel.userProfile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User profile not loaded')));
      return;
    }
    final newCurriculum = await Navigator.of(context).push<WorkoutCurriculum>(
      MaterialPageRoute(
        builder: (_) => AIChatView(
          userProfile: ref.read(homeViewModelProvider).userProfile!,
        ),
      ),
    );

    if (newCurriculum != null) {
      await viewModel.updateTodayCurriculum(newCurriculum);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _startWorkout() async {
    final viewModel = ref.read(homeViewModelProvider);
    if (viewModel.todayCurriculum == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No curriculum available')));
      return;
    }

    if (viewModel.isInProgress) {
      // Show Resume Dialog
      showDialog(
        context: context,
        builder: (context) => GlassDialog(
          title: AppLocalizations.of(context)!.resumeTitle,
          content: AppLocalizations.of(context)!.resumeDesc,
          icon: const Icon(Icons.history, color: Colors.white, size: 48),
          actions: [
            GlassButton(
              text: AppLocalizations.of(context)!.startBeginning,
              onPressed: () async {
                Navigator.pop(context);
                await viewModel.resetWorkoutProgress();
                _navigateToCamera();
              },
            ),
            GlassButton(
              text: AppLocalizations.of(context)!.resumeFromLast,
              isPrimary: true,
              onPressed: () {
                Navigator.pop(context);
                _navigateToCamera();
              },
            ),
          ],
        ),
      );
    } else {
      _navigateToCamera();
    }
  }

  void _navigateToCamera() {
    final viewModel = ref.read(homeViewModelProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraView(
          curriculum: viewModel.todayCurriculum,
          userProfile: viewModel.userProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => viewModel.loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Skeleton/Content handled in HomeHeader if needed,
                // or we can wrap it here. For now assuming HomeHeader handles null profile gracefully
                // or we can add a ShimmerHeader wrapper later.
                // But user asked for Profile First -> so we just show it.
                HomeHeader(
                  userProfile: viewModel.userProfile,
                  isCompleted: viewModel.isTodayCompleted,
                  isInProgress: viewModel.isInProgress,
                  onOpenAIChat: _openAIChat,
                  onOpenSettings: _openSettings,
                  onOpenStatistics: _openStatistics,
                  areNotificationsEnabled: viewModel.areNotificationsEnabled,
                  hasUnreadNotifications: viewModel.hasUnreadNotifications,
                  onNotificationTap: () {
                    final vm = ref.read(homeViewModelProvider);
                    vm.toggleNotifications();
                    if (vm.areNotificationsEnabled) {
                      vm.setUnreadCount(3);
                    } else {
                      vm.setUnreadCount(0);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Today's Workout Card - Granular Loading
                if (viewModel.isCurriculumLoading)
                  const ShimmerDailyStats()
                else
                  DailyStatsCard(
                    curriculum: viewModel.todayCurriculum,
                    isCompleted: viewModel.isTodayCompleted,
                    onViewDetail: () {
                      if (viewModel.todayCurriculum != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutDetailView(
                              curriculum: viewModel.todayCurriculum!,
                            ),
                          ),
                        );
                      }
                    },
                  ),

                if (viewModel.isTodayCompleted) ...[
                  const SizedBox(height: 24),
                  TomorrowWorkoutCard(curriculum: viewModel.tomorrowCurriculum),
                ],
                const SizedBox(height: 24),
                // Featured Programs and Categories in a white card container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: EdgeInsets
                        .zero, //const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Hot Categories - Granular Loading
                        viewModel.isHotCategoriesLoading
                            ? const ShimmerCategoryChips()
                            : CategoryChips(
                                categories: viewModel.hotCategories,
                                isLoading: false,
                                selectedCategory: viewModel.selectedCategory,
                                onCategorySelected: (category) {
                                  viewModel.selectCategory(category);
                                },
                              ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child:
                              // Featured Program - Granular Loading
                              viewModel.isFeaturedLoading
                              ? const ShimmerFeaturedProgram()
                              : FeaturedProgramCard(
                                  program: viewModel.featuredProgram,
                                  onRetry: () => ref
                                      .read(homeViewModelProvider)
                                      .loadData(),
                                  onTapCard: () {
                                    if (viewModel.featuredProgram != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FeaturedProgramDetailView(
                                                program:
                                                    viewModel.featuredProgram!,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildRecentActivity(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingBottomNav(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildRecentActivity() {
    return const SizedBox.shrink();
  }

  Widget _buildFloatingBottomNav() {
    final viewModel = ref.watch(homeViewModelProvider);
    // Disable buttons if curriculum is loading or null (except profile loading shouldn't block, theoretically)
    // But "Today's Workout" data is needed for start workout.
    final isDisabled =
        viewModel.isCurriculumLoading || viewModel.todayCurriculum == null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
              onTap: isDisabled ? null : _startWorkout,
              child: Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isDisabled && viewModel.isCurriculumLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      else
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        isDisabled
                            ? (viewModel.isCurriculumLoading
                                  ? 'Loading...'
                                  : 'Unavailable')
                            : AppLocalizations.of(context)!.startWorkout,
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
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: isDisabled ? null : _openAIChat,
            child: Opacity(
              opacity: isDisabled ? 0.5 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brightMarigold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
