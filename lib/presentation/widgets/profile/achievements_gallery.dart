import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/widgets/gamification/share_card.dart';
import 'package:fishfeed/services/share_service.dart';

/// Achievements gallery widget displaying all achievements in a grid layout.
///
/// Features:
/// - Grid with 3 columns showing all achievements
/// - Header with "Achievements" title and unlocked/total counter
/// - Visual distinction between locked and unlocked achievements
/// - Tap to open detail modal with share functionality
class AchievementsGallery extends ConsumerWidget {
  const AchievementsGallery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsState = ref.watch(achievementsProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (achievementsState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (achievementsState.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 8),
            Text(
              achievementsState.error ?? l10n.achievementFailedToLoad,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(achievementsProvider.notifier).refresh(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final achievements = achievementsState.achievements;
    final unlockedCount = achievementsState.unlockedCount;
    final totalCount = achievementsState.totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.achievementsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$unlockedCount/$totalCount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Achievements grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _AchievementTile(
              achievement: achievement,
              onTap: () => _showAchievementDetail(context, achievement),
            );
          },
        ),
      ],
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AchievementDetailModal(achievement: achievement),
    );
  }
}

/// Single achievement tile for the grid.
///
/// Displays differently based on locked/unlocked state:
/// - Unlocked: Colored icon with glow, title, and unlock date
/// - Locked: Greyscale icon, "???" text, and lock overlay
class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.onTap});

  final Achievement achievement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;
    final achievementType = achievement.achievementType;
    final color = achievementType?.color ?? Colors.grey;
    final icon = achievementType?.icon ?? Icons.emoji_events;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? color.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? color.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Achievement icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? color.withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest,
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isUnlocked
                          ? color
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title or ???
                  Text(
                    isUnlocked
                        ? (achievementType?.localizedTitle(
                              AppLocalizations.of(context)!,
                            ) ??
                            achievement.title)
                        : '???',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isUnlocked
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Unlock date for unlocked achievements
                  if (isUnlocked && achievement.unlockedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.MMMd(
                        Localizations.localeOf(context).languageCode,
                      ).format(achievement.unlockedAt!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Lock overlay for locked achievements
            if (!isUnlocked)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Modal bottom sheet showing achievement details.
///
/// Features:
/// - Large achievement icon
/// - Title and description
/// - Unlock date (for unlocked achievements)
/// - Progress bar (for progress-based achievements)
/// - Share button
class _AchievementDetailModal extends StatefulWidget {
  const _AchievementDetailModal({required this.achievement});

  final Achievement achievement;

  @override
  State<_AchievementDetailModal> createState() =>
      _AchievementDetailModalState();
}

class _AchievementDetailModalState extends State<_AchievementDetailModal> {
  final ShareService _shareService = ShareService();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final achievement = widget.achievement;
    final isUnlocked = achievement.isUnlocked;
    final achievementType = achievement.achievementType;
    final color = achievementType?.color ?? Colors.grey;
    final icon = achievementType?.icon ?? Icons.emoji_events;
    final targetValue = achievementType?.targetValue;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Large achievement icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color.withValues(alpha: 0.8), color],
                      )
                    : null,
                color: isUnlocked
                    ? null
                    : theme.colorScheme.surfaceContainerHighest,
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                size: 50,
                color: isUnlocked
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),

            // Achievement title
            Text(
              isUnlocked
                  ? (achievementType?.localizedTitle(l10n) ??
                      achievement.title)
                  : '???',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnlocked ? null : theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              achievementType?.localizedDescription(l10n) ??
                  achievement.description ??
                  (isUnlocked ? '' : l10n.achievementCompleteToUnlock),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Unlock date or progress
            if (isUnlocked && achievement.unlockedAt != null) ...[
              _InfoChip(
                icon: Icons.calendar_today,
                label: DateFormat.yMMMd(locale).format(achievement.unlockedAt!),
                color: color,
              ),
            ] else if (!isUnlocked &&
                targetValue != null &&
                achievement.progress > 0) ...[
              // Progress bar for progress-based achievements
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.progressLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${(achievement.progress * 100).toInt()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],

            // XP reward
            if (isUnlocked) ...[
              const SizedBox(height: 12),
              _InfoChip(
                icon: Icons.star,
                label: '+${achievement.xpReward} XP',
                color: color,
              ),
            ],

            const SizedBox(height: 24),

            // Share button (only for unlocked achievements)
            if (isUnlocked)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSharing ? null : _shareAchievement,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share),
                  label: Text(
                    _isSharing ? l10n.sharingButton : l10n.shareButton,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAchievement() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final shareCard = ShareCard.localized(
        achievement: widget.achievement,
        context: context,
      );
      await _shareService.shareAchievementWithWidget(
        widget: shareCard,
        achievement: widget.achievement,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}

/// Small info chip displaying icon and label.
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
