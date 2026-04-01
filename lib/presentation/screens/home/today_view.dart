import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/config/animation_config.dart';
import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/feeding_event.dart';
import 'package:fishfeed/presentation/providers/ad_provider.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/feeding_providers.dart';
import 'package:fishfeed/presentation/providers/purchase_provider.dart';
import 'package:fishfeed/presentation/widgets/ads/banner_ad_widget.dart';
import 'package:fishfeed/presentation/widgets/common/error_state_widget.dart';
import 'package:fishfeed/presentation/widgets/common/shimmer_widgets.dart';
import 'package:fishfeed/presentation/widgets/feeding/add_aquarium_button.dart';
import 'package:fishfeed/presentation/widgets/feeding/aquarium_status_card.dart';
import 'package:fishfeed/presentation/widgets/premium/premium_upsell_card.dart';
import 'package:fishfeed/presentation/widgets/sheets/sheets_widgets.dart';
import 'package:fishfeed/services/sync/conflict_resolver.dart';
import 'package:fishfeed/services/sync/sync_service.dart';

/// Today View displaying scheduled feedings for the current day.
///
/// Features:
/// - Pull-to-refresh for data reload
/// - Grouping by aquarium with AquariumStatusCard widgets
/// - Empty state when no feedings scheduled
/// - Shimmer loading placeholder
/// - Staggered animation for card appearance using flutter_animate
/// - Add aquarium button at the bottom
class TodayView extends ConsumerStatefulWidget {
  const TodayView({super.key});

  @override
  ConsumerState<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends ConsumerState<TodayView> {
  /// Key to trigger re-animation on refresh.
  Key _listKey = UniqueKey();

  /// Subscription to feeding conflict stream for async conflict notifications.
  StreamSubscription<SyncConflict<Map<String, dynamic>>>?
  _feedingConflictSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for async feeding conflicts (offline scenario)
    _feedingConflictSubscription = ref
        .read(syncServiceProvider)
        .feedingConflictStream
        .listen(_onFeedingConflict);
  }

  @override
  void dispose() {
    _feedingConflictSubscription?.cancel();
    super.dispose();
  }

  void _onFeedingConflict(SyncConflict<Map<String, dynamic>> conflict) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final serverVersion = conflict.serverVersion;
    final actedByName =
        serverVersion['acted_by_user_name']?.toString() ?? l10n.familyMember;
    final actedAtStr = serverVersion['acted_at']?.toString();
    final actedAt = actedAtStr != null ? DateTime.tryParse(actedAtStr) : null;
    final timeStr = actedAt != null
        ? DateFormat.Hm().format(actedAt.toLocal())
        : '?';

    final message = l10n.feedingAlreadyDoneByMember(actedByName, timeStr);

    // Styled toast for family mode conflicts
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.people_alt, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );

    // Refresh the feedings list to reflect the resolved conflict
    ref.read(todayFeedingsProvider.notifier).refresh();
  }

  Future<void> _onRefresh() async {
    // Trigger sync with server first (updates lastSyncTime)
    await ref.read(syncServiceProvider).syncNow();
    // Then refresh local data
    await ref.read(todayFeedingsProvider.notifier).refresh();
    // Trigger re-animation by changing key
    setState(() {
      _listKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayFeedingsProvider);
    final l10n = AppLocalizations.of(context)!;

    // Only show shimmer on initial load, not during refresh
    if (state.isLoading && !state.isRefreshing) {
      return const _ShimmerLoading();
    }

    if (state.hasError) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ScrollableErrorState(
          title: l10n.errorStateGenericTitle,
          description: state.error!,
          onRetry: _onRefresh,
          retryLabel: l10n.errorStateTryAgain,
          errorType: ErrorType.generic,
        ),
      );
    }

    // Always show the feedings list - it handles empty state per aquarium
    // and shows aquariums, upsell card, and add button even when no events
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: _FeedingsList(
        key: _listKey,
        feedings: state.feedings,
        showEmptyMessage: state.isEmpty,
      ),
    );
  }
}

/// Provider to track if user dismissed the upsell card this session.
final _upsellDismissedProvider = StateProvider<bool>((ref) => false);

/// List of feedings grouped by aquarium with section headers.
class _FeedingsList extends ConsumerWidget {
  const _FeedingsList({
    super.key,
    required this.feedings,
    this.showEmptyMessage = false,
  });

  final List<ComputedFeedingEvent> feedings;
  final bool showEmptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final shouldShowAds = ref.watch(shouldShowAdsProvider);
    final upsellDismissed = ref.watch(_upsellDismissedProvider);
    final aquariums = ref.watch(
      userAquariumsProvider.select((s) => s.aquariums),
    );

    // Group feedings by aquarium ID
    final groupedByAquarium = <String, List<ComputedFeedingEvent>>{};
    for (final feeding in feedings) {
      groupedByAquarium.putIfAbsent(feeding.aquariumId, () => []).add(feeding);
    }

    // Build list items: ads/upsell + aquarium cards + add button
    final items = <_ListItem>[];

    // Add banner ad placeholder at the top for free users
    if (shouldShowAds) {
      items.add(const _ListItem.bannerAd());
    }

    // Add upsell card for free users (if not dismissed)
    if (!isPremium && !upsellDismissed) {
      items.add(const _ListItem.upsellCard());
    }

    // Add empty state message if no feedings today but user has aquariums
    if (showEmptyMessage && aquariums.isNotEmpty) {
      items.add(const _ListItem.emptyMessage());
    }

    // Add aquarium sections
    for (final aquarium in aquariums) {
      final aquariumFeedings = groupedByAquarium[aquarium.id] ?? [];
      items.add(_ListItem.aquariumSection(aquarium, aquariumFeedings));
    }

    // Add "Add Aquarium" button at the end
    items.add(const _ListItem.addAquariumButton());

    // Calculate offset for staggered animation (non-aquarium items at top)
    final nonAquariumOffset =
        (shouldShowAds ? 1 : 0) +
        (!isPremium && !upsellDismissed ? 1 : 0) +
        (showEmptyMessage && aquariums.isNotEmpty ? 1 : 0);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        // Banner ad and upsell card don't need animation
        if (item.isBannerAd) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: BannerAdWidget(padding: EdgeInsets.zero),
          );
        }

        if (item.isUpsellCard) {
          return PremiumUpsellCard(
            onDismiss: () {
              ref.read(_upsellDismissedProvider.notifier).state = true;
            },
          );
        }

        if (item.isAddAquariumButton) {
          return const AddAquariumButton();
        }

        if (item.isEmptyMessage) {
          final l10n = AppLocalizations.of(context)!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.emptyStateTodayDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Calculate stagger delay for this item
        final animationIndex = (index - nonAquariumOffset).clamp(0, 15);
        final staggerDelay = Duration(
          milliseconds:
              animationIndex * AnimationConfig.staggerInterval.inMilliseconds,
        );

        // Aquarium status card with swipe-left and long-press to open sheet
        if (item.isAquariumSection) {
          final aquarium = item.aquarium!;
          final Widget card = AquariumStatusCard(
            aquarium: aquarium,
            feedings: item.aquariumFeedings!,
          );

          final Widget child = Dismissible(
            key: Key('aquarium_${aquarium.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              unawaited(HapticFeedback.mediumImpact());
              showAquariumCardSheet(context, aquarium.id);
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.aquariumDetails,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                showAquariumCardSheet(context, aquarium.id);
              },
              child: card,
            ),
          );

          if (AnimationConfig.shouldReduceMotion(context)) {
            return child;
          }
          return child
              .animate(delay: staggerDelay)
              .fadeIn(
                duration: AnimationConfig.durationNormal,
                curve: AnimationConfig.entranceCurve,
              )
              .slideY(
                begin: 0.1,
                end: 0,
                duration: AnimationConfig.durationNormal,
                curve: AnimationConfig.entranceCurve,
              );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Helper class for building mixed list with headers and items.
class _ListItem {
  const _ListItem.bannerAd()
    : aquarium = null,
      aquariumFeedings = null,
      isBannerAd = true,
      isUpsellCard = false,
      isAquariumSection = false,
      isAddAquariumButton = false,
      isEmptyMessage = false;

  const _ListItem.upsellCard()
    : aquarium = null,
      aquariumFeedings = null,
      isBannerAd = false,
      isUpsellCard = true,
      isAquariumSection = false,
      isAddAquariumButton = false,
      isEmptyMessage = false;

  const _ListItem.aquariumSection(this.aquarium, this.aquariumFeedings)
    : isBannerAd = false,
      isUpsellCard = false,
      isAquariumSection = true,
      isAddAquariumButton = false,
      isEmptyMessage = false;

  const _ListItem.addAquariumButton()
    : aquarium = null,
      aquariumFeedings = null,
      isBannerAd = false,
      isUpsellCard = false,
      isAquariumSection = false,
      isAddAquariumButton = true,
      isEmptyMessage = false;

  const _ListItem.emptyMessage()
    : aquarium = null,
      aquariumFeedings = null,
      isBannerAd = false,
      isUpsellCard = false,
      isAquariumSection = false,
      isAddAquariumButton = false,
      isEmptyMessage = true;

  final Aquarium? aquarium;
  final List<ComputedFeedingEvent>? aquariumFeedings;
  final bool isBannerAd;
  final bool isUpsellCard;
  final bool isAquariumSection;
  final bool isAddAquariumButton;
  final bool isEmptyMessage;
}

/// Shimmer loading placeholder for feedings list.
class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const ShimmerFeedingCard();
      },
    );
  }
}
