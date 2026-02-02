import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/featured_program.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

class FeaturedProgramDetailView extends ConsumerWidget {
  final FeaturedProgram program;

  const FeaturedProgramDetailView({super.key, required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNetworkImage = program.imageUrl.startsWith('http');
    final curriculum = program.workoutCurriculum;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Hero Header
              SliverAppBar(
                expandedHeight: 420,
                pinned: true,
                backgroundColor: AppTheme.background,
                stretch: true,
                leading: Container(
                  margin: const EdgeInsets.only(left: 16, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      isNetworkImage
                          ? Image.network(program.imageUrl, fit: BoxFit.cover)
                          : Image.asset(program.imageUrl, fit: BoxFit.cover),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.transparent,
                              AppTheme.background.withValues(alpha: 0.8),
                              AppTheme.background,
                            ],
                            stops: const [0.0, 0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge / Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.irisOrchid.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.irisOrchid.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          program.difficulty.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.irisOrchid,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title & Slogan
                      Text(
                        program.title,
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        program.slogan,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Row
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStat(
                              'Rating',
                              program.rating.toString(),
                              Icons.star_rounded,
                              Colors.amber,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                            _buildStat(
                              'Members',
                              program.membersCount,
                              Icons.people_rounded,
                              AppTheme.capri,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                            _buildStat(
                              'Duration',
                              curriculum != null
                                  ? '${curriculum.estimatedMinutes} min'
                                  : 'N/A',
                              Icons.timer_rounded,
                              AppTheme.irisOrchid,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Description
                      Text(
                        'About Program',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        program.description,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Exercises List Header
                      if (curriculum != null &&
                          curriculum.workoutTasks.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Included Exercises',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${curriculum.workoutTasks.length} Tasks',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // 3. Exercise List Items
              if (curriculum != null && curriculum.workoutTasks.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = curriculum.workoutTasks[index];
                      final isLast =
                          index == curriculum.workoutTasks.length - 1;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              image: task.thumbnail.isNotEmpty
                                  ? DecorationImage(
                                      image: task.thumbnail.startsWith('http')
                                          ? NetworkImage(task.thumbnail)
                                          : AssetImage(task.thumbnail)
                                                as ImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: task.thumbnail.isEmpty
                                ? Icon(
                                    Icons.fitness_center,
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  )
                                : null,
                          ),
                          title: Text(
                            task.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _formatTaskDuration(task),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.background,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                              color: AppTheme.capri,
                            ),
                          ),
                        ),
                      );
                    }, childCount: curriculum.workoutTasks.length),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No preview available',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // 4. Sticky Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withValues(alpha: 0.0),
                    AppTheme.background.withValues(alpha: 0.9),
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(homeViewModelProvider).setFeaturedAsToday();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Applied to dashboard')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    elevation: 8,
                    shadowColor: AppTheme.irisOrchid.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.capri, AppTheme.irisOrchid],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        'Start Program Now',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTaskDuration(dynamic task) {
    // Assuming task has durationSec or reps
    if (task.category.toLowerCase() == 'stretch' ||
        (task.reps <= 1 && !task.isCountable)) {
      return 'Relax & Stretch';
    }
    final int validTime = task.durationSec ?? task.timeoutSec ?? 60;
    if (task.reps == 0) {
      return '$validTime Sec';
    }
    return '${task.adjustedReps} Reps × ${task.adjustedSets} Sets';
  }
}
