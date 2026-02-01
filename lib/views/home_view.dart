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

  void _openAIChat() {
    final viewModel = ref.read(homeViewModelProvider);
    if (viewModel.userProfile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User profile not loaded')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AIChatView(
          userProfile: ref.read(homeViewModelProvider).userProfile!,
        ),
      ),
    );
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
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref.read(homeViewModelProvider).loadData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(viewModel),
                      const SizedBox(height: 24),
                      _buildDailyStats(viewModel),
                      const SizedBox(height: 24),
                      _buildCategoryChips(viewModel),
                      const SizedBox(height: 24),
                      if (viewModel.featuredProgram != null)
                        _buildFeaturedProgramCard(viewModel),
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

  Widget _buildHeader(HomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.welcomeUser(viewModel.userProfile?.nickname ?? 'User'),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppTheme.textSecondary, // Slate 500
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.readyToWorkout,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    color: AppTheme.textPrimary, // Slate 900
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _openAIChat,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brightMarigold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _openSettings,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brightMarigold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStats(HomeViewModel viewModel) {
    final curriculum = viewModel.todayCurriculum;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 220, // Adjusted height for background image
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.capri, AppTheme.kiwiColada],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cloudDancer.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.todayWorkout,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (curriculum != null)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WorkoutDetailView(curriculum: curriculum),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.viewDetail,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (curriculum != null) ...[
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          curriculum.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Small Exercise Thumbnails and Estimated Time
                    Row(
                      children: [
                        SizedBox(
                          height: 45, // Smaller thumbnails
                          child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: curriculum.workoutTasks.length,
                            itemBuilder: (context, index) {
                              final task = curriculum.workoutTasks[index];
                              return Container(
                                width: 45,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  image: task.thumbnail.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(task.thumbnail),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: task.thumbnail.isNotEmpty
                                    ? null
                                    : Center(
                                        child: Text(
                                          task.title,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                        const Spacer(),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${curriculum.estimatedMinutes}',
                                style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: ' Min',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(HomeViewModel viewModel) {
    if (viewModel.isHotCategoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.hotCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            AppLocalizations.of(context)!.dailyHotCategories,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textPrimary, // Dark text
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: viewModel.hotCategories.length,
            itemBuilder: (context, index) {
              final category = viewModel.hotCategories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  shape: const StadiumBorder(
                    side: BorderSide(color: Color(0xFFE2E8F0)),
                  ), // Slate 200 border
                  label: Text(
                    category,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B), // Slate 500
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Placeholder for other build methods - will be implemented in next iteration
  Widget _buildFeaturedProgramCard(HomeViewModel viewModel) {
    if (viewModel.featuredProgram == null) {
      // Show error message as requested by user instead of hiding
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.error.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.failedToLoadFeatured,
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(homeViewModelProvider).loadData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    // final program = viewModel.featuredProgram!; // Unused in new design
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          viewModel.setFeaturedAsToday();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Applied to dashboard')));
        },
        child: Container(
          height: 420, // Taller card as per design
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                AppTheme.capri, // Blue (15-4722 TCX)
                AppTheme.irisOrchid, // Purple (17-3323 TCX)
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.irisOrchid.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Workout Image (Dynamic Placement)
              // Using lunge_01 as per request to use existing assets
              Positioned(
                right: -40,
                top: 60,
                bottom: 0,
                child: Image.asset(
                  'assets/images/workouts/lunge_01.png',
                  fit: BoxFit.contain,
                ),
              ),

              // 1.5 Blur Gradient Effect (Bottom-Center)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        AppTheme.irisOrchid.withOpacity(
                          0.9,
                        ), // Deep blurred effect at bottom
                        AppTheme.irisOrchid.withOpacity(0.0), // Fades out
                      ],
                    ),
                  ),
                ),
              ),

              // Optional: Backdrop filter for true "blur" if supported performantly
              // Keeping it simple with gradient first as "blur gradient" often means soft fade
              // If true frost is needed:
              /*
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 200,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              */

              // 2. Content Overlay
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.pickAProgram,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.fullyCustomizableProgram,
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        // Dot Indicator (Replcaing Star Rating)
                        Row(
                          children: List.generate(
                            5,
                            (index) => Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: index == 4 ? 8 : 4,
                              height: index == 4 ? 8 : 4,
                              decoration: BoxDecoration(
                                color: index == 4
                                    ? Colors.transparent
                                    : Colors.white.withOpacity(0.6),
                                shape: BoxShape.circle,
                                border: index == 4
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Avatar Group
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 24,
                          child: Stack(
                            children: List.generate(3, (index) {
                              return Positioned(
                                left: index * 16.0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    color: Colors.grey[300],
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                        'https://i.pravatar.cc/150?img=12',
                                      ), // Use mock or viewModel profile
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '5.8k+\n${AppLocalizations.of(context)!.members}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Main Title Description
                    SizedBox(
                      width: 200, // Constrain width to wrap text nicely
                      child: Text(
                        'Get Set, Stay\nIgnite, Finish Proud.\nJoin The Flow.',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Floating Action Button
              Positioned(
                bottom: 28,
                right: 28,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.arrow_outward,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
