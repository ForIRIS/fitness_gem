import 'package:flutter/material.dart';

class CurriculumLoadingCard extends StatefulWidget {
  const CurriculumLoadingCard({super.key});

  @override
  State<CurriculumLoadingCard> createState() => _CurriculumLoadingCardState();
}

class _CurriculumLoadingCardState extends State<CurriculumLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Placeholder
          _buildShimmerBlock(width: 150, height: 24),
          const SizedBox(height: 12),
          // Description lines
          _buildShimmerBlock(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          _buildShimmerBlock(width: 200, height: 14),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              _buildShimmerBlock(width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBlock(width: 80, height: 14),
                  const SizedBox(height: 8),
                  _buildShimmerBlock(width: 40, height: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Button Placeholder
          _buildShimmerBlock(
            width: double.infinity,
            height: 48,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBlock({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        );
      },
    );
  }
}
