import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/di/injection.dart';
import '../domain/entities/workout_session.dart';
import '../domain/usecases/session/get_weekly_sessions_usecase.dart';
import '../domain/usecases/session/get_monthly_sessions_usecase.dart';
import '../l10n/app_localizations.dart';
import 'widgets/shareable_card_widget.dart';

/// Statistics View - Shows workout progress visualizations
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.progress,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildWeeklyView(), _buildMonthlyView()],
            ),
    );
  }

  Widget _buildWeeklyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                color: Colors.white,
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
      padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withValues(alpha: 0.2),
            Colors.blueAccent.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Workouts',
                totalWorkouts.toString(),
                Icons.fitness_center,
              ),
              _buildStatItem(
                'Duration',
                '${(totalDuration / 60).ceil()} min',
                Icons.timer,
              ),
              _buildStatItem(
                'Avg Form',
                '${(avgFormScore * 100).toStringAsFixed(0)}%',
                Icons.analytics,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purpleAccent.withValues(alpha: 0.2),
            Colors.blueAccent.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: Colors.purpleAccent,
                size: 28,
              ),
              const SizedBox(width: 8),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Workouts',
                totalWorkouts.toString(),
                Icons.fitness_center,
              ),
              _buildStatItem(
                'Total Time',
                '${(totalDuration / 60).ceil()} min',
                Icons.timer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 48),
            const SizedBox(height: 12),
            Text(
              'No workouts recorded yet',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete a workout to see your stats!',
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    // Group sessions by day of week
    final now = DateTime.now();
    final daysOfWeek = List.generate(7, (i) {
      return now.subtract(Duration(days: 6 - i));
    });

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
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Duration (minutes)',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: dataByDay.values.isEmpty
                    ? 60
                    : (dataByDay.values.reduce((a, b) => a > b ? a : b) * 1.2)
                          .toDouble(),
                barGroups: List.generate(7, (i) {
                  final isToday = i == 6;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: (dataByDay[i] ?? 0).toDouble(),
                        color: isToday ? Colors.greenAccent : Colors.blueAccent,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
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
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final dayIndex = daysOfWeek[value.toInt()].weekday - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[dayIndex],
                            style: GoogleFonts.outfit(
                              color: Colors.grey[500],
                              fontSize: 12,
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
                gridData: const FlGridData(show: false),
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
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Frequency (per week)',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final weeks = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
                        if (value.toInt() >= 0 && value.toInt() < 4) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              weeks[value.toInt()],
                              style: GoogleFonts.outfit(
                                color: Colors.grey[500],
                                fontSize: 10,
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
                    color: Colors.purpleAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
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
          'Recent Sessions',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.greenAccent,
              size: 24,
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
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.durationMinutes} min • ${session.totalReps} reps',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey[400],
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
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              if (session.avgFormScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getFormScoreColor(
                      session.avgFormScore,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(session.avgFormScore * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
    if (score >= 0.8) return Colors.greenAccent;
    if (score >= 0.6) return Colors.yellowAccent;
    return Colors.orangeAccent;
  }
}
