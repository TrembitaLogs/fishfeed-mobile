import 'package:flutter/material.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/core/constants/achievements.dart';
import 'package:fishfeed/domain/entities/achievement.dart';
import 'package:fishfeed/presentation/providers/achievement_providers.dart';
import 'package:fishfeed/presentation/widgets/common/empty_state_widget.dart';
import 'package:fishfeed/presentation/widgets/common/error_state_widget.dart';
import 'package:fishfeed/presentation/widgets/gamification/share_card.dart';
import 'package:fishfeed/services/share_service.dart';

/// Screen displaying all achievements in a grid layout.
///
/// Shows:
/// - Unlocked achievements with full color and unlock date
/// - Locked achievements with silhouette (greyed out)
/// - Progress indicators for partial achievements
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(allAchievementsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle), centerTitle: true),
      body: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.emoji_events_outlined,
              title: l10n.emptyStateAchievementsTitle,
              description: l10n.emptyStateAchievementsDescription,
            );
          }
          return _buildContent(context, ref, achievements);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateWidget(
          title: l10n.errorStateGenericTitle,
          description: l10n.errorStateGenericDescription,
          onRetry: () async => ref.invalidate(allAchievementsProvider),
          retryLabel: l10n.errorStateTryAgain,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Achievement> achievements,
  ) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;

    return CustomScrollView(
      slivers: [
        // Header with progress
        SliverToBoxAdapter(
          child: _buildHeader(context, unlockedCount, totalCount),
        ),

        // Achievements grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _AchievementCard(achievement: achievements[index]),
              childCount: achievements.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 32),
              const SizedBox(width: 12),
              Text(
                '$unlocked / $total',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.achievementProgressTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card widget displaying a single achievement.
class _AchievementCard extends StatefulWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> {
  final ShareService _shareService = ShareService();
  bool _isSharing = false;

  Achievement get achievement => widget.achievement;

  Future<void> _shareAchievement() async {
    if (_isSharing || !achievement.isUnlocked) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final shareCard = ShareCard.localized(
        achievement: achievement,
        context: context,
      );
      await _shareService.shareAchievementWithWidget(
        widget: shareCard,
        achievement: achievement,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final achievementType = achievement.achievementType;
    final color = isUnlocked
        ? (achievementType?.color ?? Colors.amber)
        : Colors.grey.shade400;
    final icon = achievementType?.icon ?? Icons.emoji_events;

    return Card(
      elevation: isUnlocked ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUnlocked
            ? BorderSide(color: color.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        onLongPress: isUnlocked ? _shareAchievement : null,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: isUnlocked
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.1),
                          color.withValues(alpha: 0.05),
                        ],
                      ),
                    )
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isUnlocked
                              ? color.withValues(alpha: 0.2)
                              : Colors.grey.shade200,
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: isUnlocked ? color : Colors.grey.shade400,
                        ),
                      ),
                      if (!isUnlocked && achievement.progress > 0)
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: achievement.progress,
                            strokeWidth: 3,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              color.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    achievement.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? null : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Status or progress
                  if (isUnlocked) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(achievement.unlockedAt!, context),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: color),
                        ),
                      ],
                    ),
                  ] else if (achievement.progress > 0) ...[
                    Text(
                      '${(achievement.progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.achievementLocked,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Share icon for unlocked achievements
            if (isUnlocked)
              Positioned(
                top: 8,
                right: 8,
                child: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.share,
                        size: 18,
                        color: color.withValues(alpha: 0.6),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMd(locale).format(date);
  }

  void _showDetails(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final achievementType = achievement.achievementType;
    final color = isUnlocked
        ? (achievementType?.color ?? Colors.amber)
        : Colors.grey.shade400;
    final icon = achievementType?.icon ?? Icons.emoji_events;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? color.withValues(alpha: 0.2)
                    : Colors.grey.shade200,
              ),
              child: Icon(
                icon,
                size: 40,
                color: isUnlocked ? color : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              achievement.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            if (achievement.description != null)
              Text(
                achievement.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),

            // XP Reward
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status
            if (isUnlocked) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: color),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.achievementUnlockedOn(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).languageCode,
                      ).format(achievement.unlockedAt!),
                    ),
                    style: TextStyle(color: color),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Share button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _shareAchievement();
                },
                icon: const Icon(Icons.share, size: 18),
                label: Text(AppLocalizations.of(context)!.shareButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ] else if (achievement.progress > 0) ...[
              Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.achievementProgress(
                      (achievement.progress * 100).toInt(),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.achievementNotYetUnlocked,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
