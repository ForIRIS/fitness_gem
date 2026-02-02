import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/workout_task.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

class WorkoutDetailCard extends StatefulWidget {
  final WorkoutTask task;
  final int index;
  final bool isActive;

  const WorkoutDetailCard({
    super.key,
    required this.task,
    required this.index,
    required this.isActive,
  });

  @override
  State<WorkoutDetailCard> createState() => _WorkoutDetailCardState();
}

class _WorkoutDetailCardState extends State<WorkoutDetailCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initialize video controller if URL is present
    if (widget.task.exampleVideoUrl.isNotEmpty) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.task.exampleVideoUrl.isEmpty) return;

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.task.exampleVideoUrl),
      );
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0); // Mute

      if (widget.isActive) {
        _videoController!.play();
      }

      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      debugPrint('Media URL refresh skipped - immutable entity limitation');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if it's maintenance/stretch
    final bool isMaintenance =
        (widget.task.reps <= 1 && !widget.task.isCountable) ||
        widget.task.category.toLowerCase() == 'stretch';

    // Format Subtitle
    String subtitleText;
    final int validTime =
        widget.task.durationSec ??
        widget.task.timeoutSec; // Prefer duration, fallback to timeout
    final int displayTime = validTime > 0
        ? validTime
        : 60; // Default to 60 if both 0

    if (isMaintenance) {
      subtitleText = 'Relax & Stretch';
    } else if (widget.task.reps == 0) {
      // Duration only task
      subtitleText = '$displayTime Sec per set';
    } else {
      // Reps + Duration task
      subtitleText =
          '${widget.task.adjustedReps} Reps / $displayTime Sec per set';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB08CDD),
            Color(0xFF9670BF),
          ], // Soft Purple Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9670BF).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // No fixed height, let it grow
      child: Stack(
        children: [
          // Background Image (Expanded with card)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: MediaQuery.of(context).size.width * 0.65,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.6, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: _buildSimpleVisualPreview(),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Leading (Left)
            mainAxisSize: MainAxisSize.min, // Hug content
            children: [
              // 1. Main Content (Collapsed View)
              SizedBox(
                height: 180, // Keep collapsed height consistent for layout
                child: Stack(
                  children: [
                    // Right-side Image (Trailing, 2/3 width)

                    // Content Overlay (Text)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tag (Pill shape)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isMaintenance
                                  ? AppLocalizations.of(context)!.hold
                                  : '${widget.task.adjustedSets} Sets',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          SizedBox(
                            width: 180,
                            child: Text(
                              widget.task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtext / Reps
                          Text(
                            subtitleText,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Expanded Content (Description & Advice)
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    0,
                    84,
                    24,
                  ), // right:84 avoids button overlap, bottom:24 removes excess space
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        'Description',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.task.description,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Expert Advice',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.task.advice,
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
            ],
          ),

          // 3. Circular Arrow Button (Toggle Trigger)
          Positioned(
            bottom: 24,
            right: 24,
            child: GestureDetector(
              onTap: _toggleExpansion,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: _isExpanded ? -0.25 : 0.25, // Rotate 90 deg down
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    color: _isExpanded
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simplified visual for the card
  Widget _buildSimpleVisualPreview() {
    if (_isVideoInitialized && _videoController != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else if (widget.task.thumbnail.isNotEmpty) {
      if (widget.task.thumbnail.startsWith('http')) {
        return Image.network(
          widget.task.thumbnail,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        return Image.asset(
          widget.task.thumbnail,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    } else {
      // Fallback: Try to use ID to find local asset
      return Image.asset(
        'assets/images/workouts/${widget.task.id}.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.fitness_center,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
