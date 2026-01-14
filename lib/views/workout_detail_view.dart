import 'package:flutter/material.dart';
import '../models/workout_curriculum.dart';
import '../models/workout_task.dart';

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
      viewportFraction: 0.9,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.curriculum.workoutTaskList.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final task = widget.curriculum.workoutTaskList[index];
                  // Calculate scale/opacity for active vs inactive items
                  final isCurrent = index == _currentIndex;
                  final scale = isCurrent ? 1.0 : 0.9;
                  final opacity = isCurrent ? 1.0 : 0.5;

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: _buildWorkoutCard(task, index),
                    ),
                  );
                },
              ),
            ),

            // Add some bottom padding
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutTask task, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark background matching design
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Color(0xFF00E676), // Green accent color
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title & Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatStats(task),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            task.description, // Using English description as subtitle/summary
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 16,
              height: 1.4,
            ),
          ),

          const Spacer(),

          // Korean Advice Box (KR ADVICE)
          if (task.koreanAdvice != null && task.koreanAdvice!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1410), // Very dark green/black
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B5E20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'KR ADVICE: ',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: task.koreanAdvice,
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Preview Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Currently close, but could play video later
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'PREVIEW',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStats(WorkoutTask task) {
    if (task.category == 'core') {
      return '${task.timeoutSec} SEC EACH\n${task.adjustedSets} SETS'; // Core usually time based
    }
    return '${task.adjustedReps} REPS\n${task.adjustedSets} SETS';
  }
}
