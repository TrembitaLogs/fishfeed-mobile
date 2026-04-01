import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fishfeed/domain/entities/family_invite.dart';
import 'package:fishfeed/domain/entities/family_member.dart';
import 'package:fishfeed/domain/entities/subscription_status.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/family_provider.dart';
import 'package:fishfeed/presentation/screens/settings/widgets/family_widgets.dart';

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
  const FamilyScreen({super.key, required this.aquariumId, this.aquariumName});

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
      ref
          .read(familyNotifierProvider.notifier)
          .loadFamilyData(widget.aquariumId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Determine subscription status and limits
    final isPremium =
        currentUser?.subscriptionStatus == SubscriptionStatus.premium();
    final maxMembers = isPremium ? kMaxPremiumTierMembers : kMaxFreeTierMembers;
    final memberCount = state.members.length;
    final hasReachedLimit = memberCount >= maxMembers;
    final isOwner = state.members.any(
      (m) => m.isOwner && m.userId == currentUser?.id,
    );
    final canInvite = isOwner && !hasReachedLimit && !state.isLoading;

    final l10n = AppLocalizations.of(context)!;

    // Listen for newly created invite to trigger share
    ref.listen<FamilyState>(familyNotifierProvider, (previous, next) {
      if (next.lastCreatedInvite != null &&
          previous?.lastCreatedInvite != next.lastCreatedInvite) {
        _showShareInviteSheet(next.lastCreatedInvite!);
      }
      if (next.error != null && previous?.error != next.error) {
        _showErrorSnackBar(next.error!.message ?? l10n.errorOccurred);
      }
    });

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
                  const SliverToBoxAdapter(child: FamilyHeader()),

                  // Member limit indicator (free tier, owner only)
                  if (!isPremium && isOwner)
                    SliverToBoxAdapter(
                      child: FamilyMemberLimitIndicator(
                        currentCount: memberCount,
                        maxCount: maxMembers,
                      ),
                    ),

                  // Invite button or upgrade prompt (owner only)
                  if (isOwner)
                    SliverToBoxAdapter(
                      child: hasReachedLimit && !isPremium
                          ? FamilyUpgradePrompt(
                              maxPremiumMembers: kMaxPremiumTierMembers,
                              onUpgrade: _showPremiumUpgrade,
                            )
                          : FamilyInviteButton(
                              isLoading: state.isLoading,
                              canInvite: canInvite,
                              onInvite: _createInvite,
                            ),
                    ),

                  // Active invitations section (owner only)
                  if (isOwner && state.invites.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: FamilySectionHeader(
                        title: l10n.activeInvitations,
                        icon: Icons.mail_outline,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => FamilyInviteCard(
                          invite: state.invites[index],
                          onShare: () => _shareInvite(state.invites[index]),
                          onCancel: () =>
                              _cancelInvite(state.invites[index].id),
                        ),
                        childCount: state.invites.length,
                      ),
                    ),
                  ],

                  // Family members section
                  SliverToBoxAdapter(
                    child: FamilySectionHeader(
                      title: l10n.familyMembers,
                      icon: Icons.people_outline,
                    ),
                  ),
                  if (state.members.isEmpty)
                    const SliverToBoxAdapter(child: FamilyEmptyMembersMessage())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final member = state.members[index];
                        // Owner can remove any member; member can leave (remove self)
                        final isSelf = member.userId == currentUser?.id;
                        final canRemove =
                            !member.isOwner && (isOwner || isSelf);
                        return FamilyMemberCard(
                          member: member,
                          onRemove: canRemove
                              ? () => _removeMember(member)
                              : null,
                          isPremium: isPremium,
                          // TODO: Add actual feeding stats from API when available
                          feedingsThisWeek: isPremium ? 0 : null,
                          feedingsThisMonth: isPremium ? 0 : null,
                        );
                      }, childCount: state.members.length),
                    ),

                  // Bottom padding
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.premiumComingSoon)));
  }

  void _shareInvite(FamilyInvite invite) {
    final l10n = AppLocalizations.of(context)!;
    final shareText = l10n.joinMyAquarium(invite.deepLink, invite.inviteCode);

    Share.share(shareText, subject: l10n.invitationToFishFeed);
  }

  void _showShareInviteSheet(FamilyInvite invite) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FamilyShareInviteSheet(
        invite: invite,
        onShare: () {
          Navigator.pop(context);
          _shareInvite(invite);
        },
        onCopy: () {
          Clipboard.setData(ClipboardData(text: invite.deepLink));
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
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
        ref
            .read(familyNotifierProvider.notifier)
            .cancelInvite(widget.aquariumId, inviteId);
      }
    });
  }

  void _removeMember(FamilyMember member) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.read(currentUserProvider);
    final isSelf = member.userId == currentUser?.id;

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSelf ? l10n.leaveFamily : l10n.removeMember),
        content: Text(
          isSelf
              ? l10n.leaveFamilyDescription
              : l10n.removeMemberDescription(member.displayName ?? l10n.user),
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
            child: Text(isSelf ? l10n.leave : l10n.remove),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref
            .read(familyNotifierProvider.notifier)
            .removeMember(widget.aquariumId, member.userId);
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
