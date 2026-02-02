import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cache_service.dart';
import '../presentation/viewmodels/home_viewmodel.dart';
import 'camera_view.dart';
import 'settings_view.dart';
import 'ai_chat_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'workout_detail_view.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../domain/entities/workout_curriculum.dart';
import 'widgets/home/home_header.dart';
import 'widgets/home/daily_stats_card.dart';
import 'widgets/home/category_chips.dart';
import 'widgets/home/featured_program_card.dart';
import 'widgets/home/home_shimmer_widgets.dart';

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

  void _startWorkout() {
    final viewModel = ref.read(homeViewModelProvider);
    if (viewModel.todayCurriculum == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No curriculum available')));
      return;
    }

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
      backgroundColor: const Color(0xFFF2F4F7), // Cloud Dancer approx
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(homeViewModelProvider).loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                HomeHeader(
                  userProfile: viewModel.userProfile,
                  onOpenAIChat: _openAIChat,
                  onOpenSettings: _openSettings,
                ),
                const SizedBox(height: 24),
                viewModel.isLoading
                    ? const ShimmerDailyStats()
                    : DailyStatsCard(
                        curriculum: viewModel.todayCurriculum,
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
                const SizedBox(height: 24),
                viewModel.isLoading || viewModel.isHotCategoriesLoading
                    ? const ShimmerCategoryChips()
                    : CategoryChips(
                        categories: viewModel.hotCategories,
                        isLoading: viewModel.isHotCategoriesLoading,
                      ),
                const SizedBox(height: 24),
                viewModel.isLoading
                    ? const ShimmerFeaturedProgram()
                    : FeaturedProgramCard(
                        program: viewModel.featuredProgram,
                        onApply: () {
                          viewModel.setFeaturedAsToday();
                        },
                        onRetry: () =>
                            ref.read(homeViewModelProvider).loadData(),
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

  // Shimmer Widgets

  Widget _buildRecentActivity() {
    // Placeholder - can be expanded later with actual history data
    return const SizedBox.shrink();
  }

  Widget _buildFloatingBottomNav() {
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
            child: _buildNavPill(
              AppLocalizations.of(context)!.startWorkout,
              onTap: _startWorkout,
            ),
          ),
          const SizedBox(width: 8),
          _buildNavIcon(
            Icons.auto_awesome,
            AppLocalizations.of(context)!.aiChat,
            false,
            onTap: _openAIChat,
          ),
        ],
      ),
    );
  }

  Widget _buildNavPill(String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.brightMarigold,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
