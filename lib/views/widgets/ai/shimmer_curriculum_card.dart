import 'package:flutter/material.dart';

class ShimmerCurriculumCard extends StatefulWidget {
  const ShimmerCurriculumCard({super.key});

  @override
  State<ShimmerCurriculumCard> createState() => _ShimmerCurriculumCardState();
}

class _ShimmerCurriculumCardState extends State<ShimmerCurriculumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Header Shimmer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBox(width: 120, height: 16),
                  const SizedBox(height: 12),
                  _buildShimmerBox(width: 180, height: 20),
                  const SizedBox(height: 8),
                  _buildShimmerBox(width: 140, height: 14),
                ],
              ),
            ),

            // Mini Cards Shimmer
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _buildShimmerMiniCard();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Buttons Shimmer
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 44)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerBox(height: 44)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({double? width, required double height}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final value = _shimmerController.value;
        const double range = 0.5;
        final offset = (value * (1 + range * 2)) - range;

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade100,
                Colors.grey.shade50,
                Colors.grey.shade100,
              ],
              stops: [
                (offset - 0.1).clamp(0.0, 1.0),
                offset.clamp(0.0, 1.0),
                (offset + 0.1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerMiniCard() {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShimmerBox(width: 24, height: 20),
            const SizedBox(height: 8),
            _buildShimmerBox(width: 80, height: 14),
            const SizedBox(height: 4),
            _buildShimmerBox(width: 60, height: 12),
          ],
        ),
      ),
    );
  }
}
