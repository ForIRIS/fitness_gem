import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/di/injection.dart';
import '../domain/entities/workout_session.dart';
import '../domain/usecases/session/get_weekly_sessions_usecase.dart';
import '../domain/usecases/session/get_monthly_sessions_usecase.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'widgets/shareable_card_widget.dart';

/// Statistics View - Shows workout progress visualizations
/// Polished to match HomeView style (Light theme, shadows, Outfit font)
class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<WorkoutSession> _weeklySessions = [];
  List<WorkoutSession> _monthlySessions = [];
  bool _isLoading = true;

  final GetWeeklySessionsUseCase _getWeeklySessions =
      getIt<GetWeeklySessionsUseCase>();
  final GetMonthlySessionsUseCase _getMonthlySessions =
      getIt<GetMonthlySessionsUseCase>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final weeklyResult = await _getWeeklySessions.execute();
    final monthlyResult = await _getMonthlySessions.execute();

    weeklyResult.fold(
      (failure) => debugPrint('Failed to load weekly sessions: $failure'),
      (sessions) => _weeklySessions = sessions,
    );

    monthlyResult.fold(
      (failure) => debugPrint('Failed to load monthly sessions: $failure'),
      (sessions) => _monthlySessions = sessions,
    );

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 84.0, // Increased by 1.5x
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.progress,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildWeeklyView(), _buildMonthlyView()],
            ),
    );
  }

  Widget _buildWeeklyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightCard(),
          const SizedBox(height: 24),
          _buildWeeklyChart(),
          const SizedBox(height: 24),
          _buildSessionsList(_weeklySessions),
          const SizedBox(height: 24),
          if (_weeklySessions.isNotEmpty) ...[
            Text(
              'Share Your Progress',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ShareableCardWidget(
              sessions: _weeklySessions,
              periodLabel: 'This Week',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthlyInsightCard(),
          const SizedBox(height: 24),
          _buildMonthlyChart(),
          const SizedBox(height: 24),
          _buildSessionsList(_monthlySessions),
        ],
      ),
    );
  }

  // Helper method for consistent container style
  BoxDecoration _getContainerDecoration() {
    return BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildInsightCard() {
    if (_weeklySessions.isEmpty) {
      return _buildEmptyInsightCard();
    }

    final totalDuration = _weeklySessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final totalWorkouts = _weeklySessions.length;
    final avgFormScore = _weeklySessions.isNotEmpty
        ? _weeklySessions.fold<double>(0, (sum, s) => sum + s.avgFormScore) /
              _weeklySessions.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary, // Using primary color for weekly summary
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            Color(0xFF7F00FF),
          ], // Matching brand gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'This Week',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Workouts',
                totalWorkouts.toString(),
                Icons.fitness_center_rounded,
                isWhite: true,
              ),
              _buildStatItem(
                'Duration',
                '${(totalDuration / 60).ceil()} min',
                Icons.timer_rounded,
                isWhite: true,
              ),
              _buildStatItem(
                'Avg Form',
                '${(avgFormScore * 100).toStringAsFixed(0)}%',
                Icons.analytics_rounded,
                isWhite: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyInsightCard() {
    if (_monthlySessions.isEmpty) {
      return _buildEmptyInsightCard();
    }

    final totalDuration = _monthlySessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final totalWorkouts = _monthlySessions.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: LinearGradient(
          colors: [AppTheme.accent, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'This Month',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Workouts',
                totalWorkouts.toString(),
                Icons.fitness_center_rounded,
                isWhite: true,
              ),
              _buildStatItem(
                'Total Time',
                '${(totalDuration / 60).ceil()} min',
                Icons.timer_rounded,
                isWhite: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInsightCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getContainerDecoration(),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppTheme.textSecondary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No workouts recorded yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete a workout to see your stats!',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    bool isWhite = false,
  }) {
    final textColor = isWhite ? Colors.white : AppTheme.textPrimary;
    final iconColor = isWhite
        ? Colors.white.withOpacity(0.8)
        : AppTheme.primary;
    final subTextColor = isWhite
        ? Colors.white.withOpacity(0.7)
        : AppTheme.textSecondary;

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: subTextColor),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    // Group sessions by day of week - Calendar Week (Mon -> Sun)
    final now = DateTime.now();

    // Calculate start of this week (Monday)
    // weekday: Mon=1 ... Sun=7
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Generate dates for Mon-Sun of THIS week
    final daysOfWeek = List.generate(7, (i) {
      return startOfWeek.add(Duration(days: i));
    });

    // Today's index (0=Mon, 6=Sun)
    final todayIndex = now.weekday - 1;

    final dataByDay = <int, int>{};
    for (final session in _weeklySessions) {
      final dayIndex = daysOfWeek.indexWhere(
        (d) =>
            d.year == session.date.year &&
            d.month == session.date.month &&
            d.day == session.date.day,
      );
      if (dayIndex >= 0) {
        dataByDay[dayIndex] =
            (dataByDay[dayIndex] ?? 0) + session.durationMinutes;
      }
    }

    return Container(
      height: 240, // Slightly taller for breathing room
      padding: const EdgeInsets.all(24),
      decoration: _getContainerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Activity',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Minutes',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: dataByDay.values.isEmpty
                    ? 60
                    : (dataByDay.values.reduce((a, b) => a > b ? a : b) * 1.2)
                          .toDouble(),
                barGroups: List.generate(7, (i) {
                  final isToday = i == todayIndex;
                  final isFutureDay = i > todayIndex;
                  final isPastDay = i < todayIndex;
                  final showBar = !isFutureDay;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: showBar ? (dataByDay[i] ?? 0).toDouble() : 0,
                        gradient: isToday
                            ? AppTheme.primaryGradient
                            : (isPastDay
                                  ? LinearGradient(
                                      colors: [
                                        AppTheme.accent.withOpacity(0.7),
                                        AppTheme.accent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    )
                                  : null),
                        color: isToday || isPastDay ? null : Colors.transparent,
                        width: 12, // Sleeker bars
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: showBar && (dataByDay[i] ?? 0) == 0,
                          toY: 6, // Subtle "empty" indicator
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ];
                        final isToday = value.toInt() == todayIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            days[value.toInt()],
                            style: GoogleFonts.outfit(
                              color: isToday
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    // Group sessions by week
    final now = DateTime.now();
    final weeklyData = <int, int>{};

    for (final session in _monthlySessions) {
      final weeksAgo = ((now.difference(session.date).inDays) ~/ 7).clamp(0, 3);
      final weekIndex = 3 - weeksAgo;
      weeklyData[weekIndex] = (weeklyData[weekIndex] ?? 0) + 1;
    }

    final spots = List.generate(4, (i) {
      return FlSpot(i.toDouble(), (weeklyData[i] ?? 0).toDouble());
    });

    return Container(
      height: 240,
      padding: const EdgeInsets.all(24),
      decoration: _getContainerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Frequency',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final weeks = ['W1', 'W2', 'W3', 'W4'];
                        if (value.toInt() >= 0 && value.toInt() < 4) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              weeks[value.toInt()],
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: AppTheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: AppTheme.primary,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.2),
                          AppTheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildSessionsList(List<WorkoutSession> sessions) {
    if (sessions.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...sessions.take(5).map((session) => _buildSessionItem(session)),
      ],
    );
  }

  Widget _buildSessionItem(WorkoutSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _getContainerDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.curriculumTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.durationMinutes} min • ${session.totalReps} reps',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(session.date),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              if (session.avgFormScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getFormScoreColor(
                      session.avgFormScore,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(session.avgFormScore * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getFormScoreColor(session.avgFormScore),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.month}/${date.day}';
  }

  Color _getFormScoreColor(double score) {
    if (score >= 0.8) return AppTheme.success;
    if (score >= 0.6) return AppTheme.brightMarigold;
    return AppTheme.error;
  }
}
