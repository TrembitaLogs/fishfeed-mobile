import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// A shareable card widget displaying an achievement.
///
/// This widget is designed to be captured as an image for sharing.
/// It includes:
/// - Gradient background with app branding colors
/// - Achievement icon and title
/// - "Earned in FishFeed" branding
/// - Date when the achievement was unlocked
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.achievement,
    this.width = 400,
    this.height = 500,
    this.achievementUnlockedLabel,
    this.formattedDate,
  });

  /// The achievement to display on the card.
  final Achievement achievement;

  /// Width of the card in pixels.
  final double width;

  /// Height of the card in pixels.
  final double height;

  /// Localized "ACHIEVEMENT UNLOCKED" label. Pass from context.
  final String? achievementUnlockedLabel;

  /// Pre-formatted date string. Pass from context using locale-aware formatting.
  final String? formattedDate;

  /// Creates a ShareCard with localization from context.
  factory ShareCard.localized({
    Key? key,
    required Achievement achievement,
    required BuildContext context,
    double width = 400,
    double height = 500,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = achievement.unlockedAt != null
        ? DateFormat.yMMMd(locale).format(achievement.unlockedAt!)
        : null;

    return ShareCard(
      key: key,
      achievement: achievement,
      width: width,
      height: height,
      achievementUnlockedLabel: l10n.achievementUnlockedCard,
      formattedDate: formattedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievementType = achievement.achievementType;
    final color = achievementType?.color ?? Colors.amber;
    final icon = achievementType?.icon ?? Icons.emoji_events;
    final unlockedAt = achievement.unlockedAt;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E), // Deep indigo
            const Color(0xFF0D47A1), // Dark blue
            color.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePatternPainter(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Top section: App branding
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'FishFeed',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achievementUnlockedLabel ?? 'ACHIEVEMENT UNLOCKED',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                // Center section: Achievement icon and info
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color.withValues(alpha: 0.9), color],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Achievement title
                      Text(
                        achievement.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Achievement description
                      if (achievement.description != null)
                        Text(
                          achievement.description!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                // Bottom section: XP and date
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // XP reward badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: color, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '+${achievement.xpReward} XP',
                            style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Unlock date
                    if (formattedDate != null || unlockedAt != null)
                      Text(
                        formattedDate ?? _formatDate(unlockedAt!),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Custom painter for decorative wave pattern background.
class _WavePatternPainter extends CustomPainter {
  _WavePatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // First wave
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.8,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second wave
    final path2 = Path();
    path2.moveTo(0, size.height * 0.85);
    path2.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.75,
      size.width * 0.6,
      size.height * 0.85,
    );
    path2.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.95,
      size.width,
      size.height * 0.85,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
