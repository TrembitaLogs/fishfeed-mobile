import 'package:flutter/material.dart';

import 'package:fishfeed/domain/entities/feeding_history.dart';

class FeedingHistoryAquariumStrip extends StatelessWidget {
  const FeedingHistoryAquariumStrip({
    super.key,
    required this.breakdown,
    required this.onChipTap,
  });

  final List<AquariumSparkline> breakdown;
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final s in breakdown)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                onPressed: () => onChipTap(s.aquariumId),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.aquariumName),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 56,
                      height: 16,
                      child: CustomPaint(
                        painter: _SparklinePainter(
                          counts: s.last7DaysCounts,
                          colour: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${s.totalCountInRange}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.counts, required this.colour});
  final List<int> counts;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b);
    if (maxCount == 0) return;
    final paint = Paint()
      ..color = colour
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final stepX = size.width / (counts.length - 1);
    final path = Path();
    for (var i = 0; i < counts.length; i++) {
      final x = stepX * i;
      final y = size.height - (counts[i] / maxCount) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.counts != counts || old.colour != colour;
}
