import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/entities/workout_session.dart';

/// A shareable card widget that can be captured and shared on social media
class ShareableCardWidget extends StatefulWidget {
  final List<WorkoutSession> sessions;
  final String periodLabel; // e.g., "This Week" or "This Month"

  const ShareableCardWidget({
    super.key,
    required this.sessions,
    this.periodLabel = 'This Week',
  });

  @override
  State<ShareableCardWidget> createState() => _ShareableCardWidgetState();
}

class _ShareableCardWidgetState extends State<ShareableCardWidget> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('ShareableCard: RenderRepaintBoundary not found');
        setState(() => _isSharing = false);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/workout_progress_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Check out my workout progress! 💪 #FitnessGem');
    } catch (e) {
      debugPrint('ShareableCard: Error sharing card: $e');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildMiniChart(),
                const SizedBox(height: 20),
                _buildStats(),
                const SizedBox(height: 16),
                _buildFooter(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSharing ? null : _shareCard,
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            label: Text(_isSharing ? 'Preparing...' : 'Share Progress'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: Colors.greenAccent,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.periodLabel,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[400]),
            ),
            Text(
              'Workout Summary',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniChart() {
    if (widget.sessions.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          'No workouts recorded',
          style: GoogleFonts.outfit(color: Colors.grey[500]),
        ),
      );
    }

    // Group sessions by day
    final now = DateTime.now();
    final daysOfWeek = List.generate(
      7,
      (i) => now.subtract(Duration(days: 6 - i)),
    );

    final dataByDay = <int, int>{};
    for (final session in widget.sessions) {
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

    return SizedBox(
      height: 80,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: dataByDay.values.isEmpty
              ? 60
              : (dataByDay.values.reduce((a, b) => a > b ? a : b) * 1.2)
                    .toDouble(),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (dataByDay[i] ?? 0).toDouble(),
                  color: i == 6 ? Colors.greenAccent : Colors.blueAccent,
                  width: 12,
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
                  return Text(
                    days[dayIndex],
                    style: GoogleFonts.outfit(
                      color: Colors.grey[500],
                      fontSize: 10,
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
    );
  }

  Widget _buildStats() {
    final totalWorkouts = widget.sessions.length;
    final totalDuration = widget.sessions.fold<int>(
      0,
      (sum, s) => sum + s.durationSeconds,
    );
    final totalReps = widget.sessions.fold<int>(
      0,
      (sum, s) => sum + s.totalReps,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(totalWorkouts.toString(), 'Workouts'),
        _buildStatItem('${(totalDuration / 60).ceil()}', 'Minutes'),
        _buildStatItem(totalReps.toString(), 'Reps'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
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

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.diamond_outlined,
          color: Colors.greenAccent.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          'FitnessGem',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.greenAccent.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
