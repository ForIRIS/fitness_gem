import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/entities/workout_curriculum.dart';
import '../domain/entities/workout_task.dart';

class SessionFeedbackView extends StatefulWidget {
  final WorkoutCurriculum curriculum;

  const SessionFeedbackView({super.key, required this.curriculum});

  @override
  State<SessionFeedbackView> createState() => _SessionFeedbackViewState();
}

class _SessionFeedbackViewState extends State<SessionFeedbackView> {
  final Map<String, double> _ratings = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'Workout Complete!',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Great job! How was each exercise?',
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.curriculum.workoutTasks.length,
                itemBuilder: (context, index) {
                  final task = widget.curriculum.workoutTasks[index];
                  return _buildFeedbackCard(task);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Submit ratings to backend
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Submit Feedback',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(WorkoutTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  task.thumbnail.isNotEmpty
                      ? task.thumbnail
                      : 'https://via.placeholder.com/50', // Fallback
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey,
                    child: const Icon(Icons.fitness_center),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (starIndex) {
                final ratingValue = starIndex + 1;
                final currentRating = _ratings[task.id] ?? 0;
                return IconButton(
                  icon: Icon(
                    ratingValue <= currentRating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _ratings[task.id] = ratingValue.toDouble();
                    });
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
