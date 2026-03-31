import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

/// Header banner for the family mode screen.
class FamilyHeader extends StatelessWidget {
  const FamilyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom,
            size: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.familyMode,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.familyModeDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.8,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Indicator showing current member count vs limit.
class FamilyMemberLimitIndicator extends StatelessWidget {
  const FamilyMemberLimitIndicator({
    super.key,
    required this.currentCount,
    required this.maxCount,
  });

  final int currentCount;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAtLimit = currentCount >= maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isAtLimit ? Icons.warning_amber_rounded : Icons.people,
            size: 16,
            color: isAtLimit
                ? theme.colorScheme.error
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.membersCount(currentCount, maxCount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isAtLimit
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline,
              fontWeight: isAtLimit ? FontWeight.bold : null,
            ),
          ),
          if (isAtLimit) ...[
            const Spacer(),
            Text(
              l10n.limitReached,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Prompt to upgrade to premium when member limit is reached.
class FamilyUpgradePrompt extends StatelessWidget {
  const FamilyUpgradePrompt({
    super.key,
    required this.maxPremiumMembers,
    required this.onUpgrade,
  });

  final int maxPremiumMembers;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.workspace_premium,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.freePlanLimitReached,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.upgradeToPremiumFamily(maxPremiumMembers),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PremiumBenefit(
                      icon: Icons.people,
                      text: l10n.upToMembers(maxPremiumMembers),
                    ),
                  ),
                  Expanded(
                    child: _PremiumBenefit(
                      icon: Icons.bar_chart,
                      text: l10n.statisticsFeature,
                    ),
                  ),
                  Expanded(
                    child: _PremiumBenefit(
                      icon: Icons.person_remove,
                      text: l10n.managementFeature,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.workspace_premium),
                label: Text(l10n.goToPremium),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBenefit extends StatelessWidget {
  const _PremiumBenefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Invite button for the family screen.
class FamilyInviteButton extends StatelessWidget {
  const FamilyInviteButton({
    super.key,
    required this.isLoading,
    required this.canInvite,
    required this.onInvite,
  });

  final bool isLoading;
  final bool canInvite;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FilledButton.icon(
        onPressed: canInvite ? onInvite : null,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : const Icon(Icons.person_add),
        label: Text(l10n.inviteFamilyMember),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Section header with icon and title.
class FamilySectionHeader extends StatelessWidget {
  const FamilySectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no other family members exist.
class FamilyEmptyMembersMessage extends StatelessWidget {
  const FamilyEmptyMembersMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.youAreOnlyMember,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.inviteSomeone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for sharing a newly created invite.
class FamilyShareInviteSheet extends StatelessWidget {
  const FamilyShareInviteSheet({
    super.key,
    required this.invite,
    required this.onShare,
    required this.onCopy,
  });

  final FamilyInvite invite;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final remainingHours = invite.remainingTime.inHours;

    return Padding(
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

          // Success icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.check,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            l10n.invitationCreated,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            l10n.validForHours(remainingHours),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Invite code display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  l10n.invitationCode,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  invite.inviteCode,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.copy),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share),
                  label: Text(l10n.share),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Card displaying an active invitation.
class FamilyInviteCard extends StatelessWidget {
  const FamilyInviteCard({
    super.key,
    required this.invite,
    required this.onShare,
    required this.onCancel,
  });

  final FamilyInvite invite;
  final VoidCallback onShare;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final remainingHours = invite.remainingTime.inHours;
    final remainingMinutes = invite.remainingTime.inMinutes % 60;

    String timeText;
    if (remainingHours > 0) {
      timeText = l10n.validForHoursShort(remainingHours);
    } else if (remainingMinutes > 0) {
      timeText = l10n.validForMinutesShort(remainingMinutes);
    } else {
      timeText = l10n.expiring;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Invite code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.inviteCode,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: remainingHours < 6
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: remainingHours < 6
                                ? theme.colorScheme.error
                                : theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                onPressed: onShare,
                icon: const Icon(Icons.share),
                tooltip: l10n.share,
              ),
              IconButton(
                onPressed: onCancel,
                icon: const Icon(Icons.close),
                tooltip: l10n.cancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card displaying a family member.
class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    this.onRemove,
    this.isPremium = false,
    this.feedingsThisWeek,
    this.feedingsThisMonth,
  });

  final FamilyMember member;
  final VoidCallback? onRemove;
  final bool isPremium;
  final int? feedingsThisWeek;
  final int? feedingsThisMonth;

  String _formatJoinedDate(DateTime date, String locale) {
    return DateFormat('d MMM yyyy', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: member.avatarUrl != null
                    ? AppCachedAvatar(
                        imageUrl: member.avatarUrl,
                        radius: 20,
                        fallbackIcon: member.isOwner
                            ? Icons.star
                            : Icons.person,
                      )
                    : CircleAvatar(
                        backgroundColor: member.isOwner
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.secondaryContainer,
                        child: Icon(
                          member.isOwner ? Icons.star : Icons.person,
                          color: member.isOwner
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                        ),
                      ),
                title: Text(
                  member.displayName ?? l10n.user,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.isOwner ? l10n.owner : l10n.member,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.joinedDate(
                        _formatJoinedDate(member.joinedAt, locale),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                trailing: onRemove != null
                    ? GestureDetector(
                        onTap: onRemove,
                        child: Icon(
                          Icons.remove_circle_outline,
                          color: theme.colorScheme.error,
                        ),
                      )
                    : member.isOwner
                    ? Icon(Icons.verified, color: theme.colorScheme.primary)
                    : null,
              ),
              // Premium: Show feeding statistics
              if (isPremium &&
                  (feedingsThisWeek != null || feedingsThisMonth != null))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      if (feedingsThisWeek != null) ...[
                        _StatChip(
                          icon: Icons.calendar_view_week,
                          label: l10n.feedingsThisWeek(feedingsThisWeek!),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (feedingsThisMonth != null)
                        _StatChip(
                          icon: Icons.calendar_month,
                          label: l10n.feedingsThisMonth(feedingsThisMonth!),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
