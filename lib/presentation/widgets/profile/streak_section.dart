import 'package:flutter/material.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/streak.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';

/// Streak section widget for the profile screen.
///
/// Displays three stat cards in a row:
/// - Current streak with flame icon and animated counter
/// - Best streak with trophy icon
/// - Freeze days available with snowflake icon (tappable for info)
///
/// Features:
/// - Gradient background (orange/red fire theme)
/// - Shimmer effect during loading
/// - Glow effect when streak >= 7
/// - Special badges at milestones (7, 30, 100)
class StreakSection extends ConsumerWidget {
  const StreakSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakState = ref.watch(currentStreakProvider);

    if (streakState.isLoading) {
      return const _StreakSectionShimmer();
    }

    final streak = streakState.streak;
    if (streak == null) {
      return const SizedBox.shrink();
    }

    return _StreakSectionContent(streak: streak);
  }
}

/// Content widget displaying the streak stats.
class _StreakSectionContent extends StatelessWidget {
  const _StreakSectionContent({required this.streak});

  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final hasGlow = streak.currentStreak >= 7;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: _buildGradient(streak.currentStreak, isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: isDark
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.streakTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_getMilestoneBadge(streak.currentStreak) != null)
                  _MilestoneBadge(
                    milestone: _getMilestoneBadge(streak.currentStreak)!,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    iconColor: _getFlameColor(streak.currentStreak),
                    value: streak.currentStreak,
                    label: l10n.currentStreakLabel,
                    animate: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events,
                    iconColor: const Color(0xFFFFD700),
                    value: streak.longestStreak,
                    label: l10n.bestStreakLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FreezeCard(freezeAvailable: streak.freezeAvailable),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _buildGradient(int streakCount, bool isDark) {
    if (!isDark) {
      // Light mode: warm fire gradients
      if (streakCount >= 30) {
        return LinearGradient(
          colors: [Colors.red.shade400, Colors.orange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else if (streakCount >= 7) {
        return LinearGradient(
          colors: [Colors.orange.shade400, Colors.amber.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      } else {
        return LinearGradient(
          colors: [Colors.amber.shade300, Colors.amber.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }
    // Dark mode: Nord Polar Night gradients
    if (streakCount >= 30) {
      return const LinearGradient(
        colors: [Color(0xFF5E81AC), Color(0xFF81A1C1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (streakCount >= 7) {
      return const LinearGradient(
        colors: [Color(0xFF434C5E), Color(0xFF4C566A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF3B4252), Color(0xFF434C5E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Color _getFlameColor(int streakCount) {
    if (streakCount >= 30) {
      return Colors.red.shade700;
    } else if (streakCount >= 7) {
      return Colors.orange.shade700;
    } else {
      return Colors.amber.shade700;
    }
  }

  int? _getMilestoneBadge(int streakCount) {
    if (streakCount >= 100) return 100;
    if (streakCount >= 30) return 30;
    if (streakCount >= 7) return 7;
    return null;
  }
}

/// A single stat card displaying an icon, value, and label.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.animate = false,
  });

  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFECEFF4).withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          if (animate)
            _AnimatedCounter(value: value)
          else
            Text(
              value.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Freeze days card with tap handler for info dialog.
class _FreezeCard extends StatelessWidget {
  const _FreezeCard({required this.freezeAvailable});

  final int freezeAvailable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showFreezeInfoDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFFECEFF4).withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ac_unit, color: Colors.blue.shade400, size: 28),
            const SizedBox(height: 8),
            Text(
              freezeAvailable.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    l10n.freezeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFreezeInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.ac_unit, color: Colors.blue.shade400),
            const SizedBox(width: 8),
            Text(l10n.freezeDaysTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.freezeDaysDescription, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_month,
              text: l10n.freezeDaysPerMonth(kDefaultFreezePerMonth),
            ),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.auto_fix_high, text: l10n.freezeDaysAutoUsed),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.ac_unit,
              text: l10n.freezeDaysAvailable(freezeAvailable),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.gotItButton),
          ),
        ],
      ),
    );
  }
}

/// Info row for the freeze dialog.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

/// Animated counter widget using AnimatedSwitcher.
class _AnimatedCounter extends StatelessWidget {
  const _AnimatedCounter({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        value.toString(),
        key: ValueKey<int>(value),
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Milestone badge displayed when streak reaches 7, 30, or 100 days.
class _MilestoneBadge extends StatelessWidget {
  const _MilestoneBadge({required this.milestone});

  final int milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFECEFF4).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getMilestoneIcon(), size: 14, color: _getMilestoneColor()),
          const SizedBox(width: 4),
          Text(
            l10n.milestoneDays(milestone),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getMilestoneColor(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMilestoneIcon() {
    return switch (milestone) {
      100 => Icons.workspace_premium,
      30 => Icons.star,
      7 => Icons.bolt,
      _ => Icons.check_circle,
    };
  }

  Color _getMilestoneColor() {
    return switch (milestone) {
      100 => Colors.purple.shade700,
      30 => Colors.orange.shade700,
      7 => Colors.amber.shade700,
      _ => Colors.grey.shade700,
    };
  }
}

/// Shimmer loading placeholder for the streak section.
class _StreakSectionShimmer extends StatefulWidget {
  const _StreakSectionShimmer();

  @override
  State<_StreakSectionShimmer> createState() => _StreakSectionShimmerState();
}

class _StreakSectionShimmerState extends State<_StreakSectionShimmer>
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
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF434C5E) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerBox(height: 20, width: 80),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildShimmerCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height, required double width}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: isDark
                  ? const [
                      Color(0xFF4C566A),
                      Color(0xFF3B4252),
                      Color(0xFF4C566A),
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: isDark
                  ? const [
                      Color(0xFF4C566A),
                      Color(0xFF3B4252),
                      Color(0xFF4C566A),
                    ]
                  : [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
            ),
          ),
        );
      },
    );
  }
}
