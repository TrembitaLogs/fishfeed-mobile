import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/family_provider.dart';
import 'package:fishfeed/presentation/widgets/common/app_cached_image.dart';

/// Maximum number of family members allowed on free tier.
const int kMaxFreeTierMembers = 2;

/// Maximum number of family members allowed on premium tier.
const int kMaxPremiumTierMembers = 10;

/// Screen for managing family access to a shared aquarium.
///
/// Features:
/// - Invite family members via shareable deep link
/// - View list of family members with roles
/// - View active invitations with expiry countdown
/// - Remove family members (owner only)
class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({
    super.key,
    required this.aquariumId,
    this.aquariumName,
  });

  /// ID of the aquarium to manage family access for.
  final String aquariumId;

  /// Name of the aquarium for display purposes.
  final String? aquariumName;

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    // Load family data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyNotifierProvider.notifier).loadFamilyData(widget.aquariumId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    // Determine subscription status and limits
    final isPremium =
        currentUser?.subscriptionStatus == SubscriptionStatus.premium();
    final maxMembers = isPremium ? kMaxPremiumTierMembers : kMaxFreeTierMembers;
    final memberCount = state.members.length;
    final hasReachedLimit = memberCount >= maxMembers;
    final canInvite = !hasReachedLimit && !state.isLoading;

    final l10n = AppLocalizations.of(context)!;

    // Listen for newly created invite to trigger share
    ref.listen<FamilyState>(
      familyNotifierProvider,
      (previous, next) {
        if (next.lastCreatedInvite != null &&
            previous?.lastCreatedInvite != next.lastCreatedInvite) {
          _showShareInviteSheet(next.lastCreatedInvite!);
        }
        if (next.error != null && previous?.error != next.error) {
          _showErrorSnackBar(next.error!.message ?? l10n.errorOccurred);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.aquariumName ?? l10n.familyAccess),
        centerTitle: true,
      ),
      body: state.isLoading && state.members.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(familyNotifierProvider.notifier)
                  .loadFamilyData(widget.aquariumId),
              child: CustomScrollView(
                slivers: [
                  // Header section
                  SliverToBoxAdapter(
                    child: _buildHeader(context, theme),
                  ),

                  // Member limit indicator (free tier)
                  if (!isPremium)
                    SliverToBoxAdapter(
                      child: _buildMemberLimitIndicator(
                        context,
                        theme,
                        memberCount,
                        maxMembers,
                      ),
                    ),

                  // Invite button or upgrade prompt
                  SliverToBoxAdapter(
                    child: hasReachedLimit && !isPremium
                        ? _buildUpgradePrompt(context, theme)
                        : _buildInviteButton(context, theme, state.isLoading, canInvite),
                  ),

                  // Active invitations section
                  if (state.invites.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        context,
                        l10n.activeInvitations,
                        Icons.mail_outline,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _InviteCard(
                          invite: state.invites[index],
                          onShare: () => _shareInvite(state.invites[index]),
                          onCancel: () => _cancelInvite(state.invites[index].id),
                        ),
                        childCount: state.invites.length,
                      ),
                    ),
                  ],

                  // Family members section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      l10n.familyMembers,
                      Icons.people_outline,
                    ),
                  ),
                  if (state.members.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyMembersMessage(context),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final member = state.members[index];
                          // Only premium users can remove members (and owners can't be removed)
                          final canRemove =
                              isPremium && !member.isOwner;
                          return _MemberCard(
                            member: member,
                            onRemove: canRemove
                                ? () => _removeMember(member)
                                : null,
                            isPremium: isPremium,
                            // TODO: Add actual feeding stats from API when available
                            feedingsThisWeek: isPremium ? 0 : null,
                            feedingsThisMonth: isPremium ? 0 : null,
                          );
                        },
                        childCount: state.members.length,
                      ),
                    ),

                  // Bottom padding
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
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
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberLimitIndicator(
    BuildContext context,
    ThemeData theme,
    int currentCount,
    int maxCount,
  ) {
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

  Widget _buildUpgradePrompt(BuildContext context, ThemeData theme) {
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
                l10n.upgradeToPremiumFamily(kMaxPremiumTierMembers),
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
                      text: l10n.upToMembers(kMaxPremiumTierMembers),
                      theme: theme,
                    ),
                  ),
                  Expanded(
                    child: _PremiumBenefit(
                      icon: Icons.bar_chart,
                      text: l10n.statisticsFeature,
                      theme: theme,
                    ),
                  ),
                  Expanded(
                    child: _PremiumBenefit(
                      icon: Icons.person_remove,
                      text: l10n.managementFeature,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _showPremiumUpgrade,
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

  Widget _buildInviteButton(
    BuildContext context,
    ThemeData theme,
    bool isLoading,
    bool canInvite,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FilledButton.icon(
        onPressed: canInvite ? _createInvite : null,
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMembersMessage(BuildContext context) {
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

  void _createInvite() {
    ref.read(familyNotifierProvider.notifier).createInvite(widget.aquariumId);
  }

  void _showPremiumUpgrade() {
    final l10n = AppLocalizations.of(context)!;
    // TODO: Navigate to premium upgrade screen when available
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.premiumComingSoon),
      ),
    );
  }

  void _shareInvite(FamilyInvite invite) {
    final l10n = AppLocalizations.of(context)!;
    final shareText = l10n.joinMyAquarium(invite.deepLink, invite.inviteCode);

    Share.share(
      shareText,
      subject: l10n.invitationToFishFeed,
    );
  }

  void _showShareInviteSheet(FamilyInvite invite) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ShareInviteSheet(
        invite: invite,
        onShare: () {
          Navigator.pop(context);
          _shareInvite(invite);
        },
        onCopy: () {
          Clipboard.setData(ClipboardData(text: invite.deepLink));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.linkCopied)),
          );
        },
      ),
    );
  }

  void _cancelInvite(String inviteId) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelInvitation),
        content: Text(l10n.cancelInvitationDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(familyNotifierProvider.notifier).cancelInvite(inviteId);
      }
    });
  }

  void _removeMember(FamilyMember member) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeMember),
        content: Text(
          l10n.removeMemberDescription(member.displayName ?? l10n.user),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.remove),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(familyNotifierProvider.notifier).removeMember(member.id);
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// Widget for displaying a premium benefit item.
class _PremiumBenefit extends StatelessWidget {
  const _PremiumBenefit({
    required this.icon,
    required this.text,
    required this.theme,
  });

  final IconData icon;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.primary,
        ),
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

/// Bottom sheet for sharing a newly created invite.
class _ShareInviteSheet extends StatelessWidget {
  const _ShareInviteSheet({
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
class _InviteCard extends StatelessWidget {
  const _InviteCard({
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
class _MemberCard extends StatelessWidget {
  const _MemberCard({
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
                        fallbackIcon: member.isOwner ? Icons.star : Icons.person,
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
                      l10n.joinedDate(_formatJoinedDate(member.joinedAt, locale)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                trailing: onRemove != null
                    ? IconButton(
                        onPressed: onRemove,
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: l10n.remove,
                      )
                    : member.isOwner
                        ? Icon(
                            Icons.verified,
                            color: theme.colorScheme.primary,
                          )
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
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (feedingsThisMonth != null)
                        _StatChip(
                          icon: Icons.calendar_month,
                          label: l10n.feedingsThisMonth(feedingsThisMonth!),
                          theme: theme,
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

/// Small chip widget for displaying feeding statistics.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary,
          ),
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
