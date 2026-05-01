import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/core/di/datasource_providers.dart';
import 'package:fishfeed/services/analytics/analytics_service.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/domain/entities/feeding_history.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/feeding_history_provider.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_aquarium_picker_sheet.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_aquarium_strip.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_empty_state.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_heatmap.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_insights_row.dart';
import 'package:fishfeed/presentation/widgets/feeding_history/feeding_history_timeline.dart';

/// Full-page feeding history screen with range selector, aquarium filter,
/// "only mine" toggle, heatmap, insights, and detailed timeline.
class FeedingHistoryDetailScreen extends ConsumerStatefulWidget {
  const FeedingHistoryDetailScreen({super.key});

  @override
  ConsumerState<FeedingHistoryDetailScreen> createState() =>
      _FeedingHistoryDetailScreenState();
}

class _FeedingHistoryDetailScreenState
    extends ConsumerState<FeedingHistoryDetailScreen> {
  FeedingHistoryRange _range = FeedingHistoryRange.sixMonths;
  String? _aquariumId;
  bool _onlyMine = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncHistory = ref.watch(
      feedingHistoryProvider(
        FeedingHistoryQuery(
          range: _range,
          aquariumId: _aquariumId,
          onlyMyActions: _onlyMine,
        ),
      ),
    );
    final aquariums = ref
        .watch(aquariumLocalDataSourceProvider)
        .getAllAquariums()
        .where((a) => !a.isDeleted)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedingHistoryTitle)),
      body: Column(
        children: [
          _RangeChips(
            current: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
          if (aquariums.length >= 2)
            ListTile(
              leading: const Icon(Icons.water),
              title: Text(
                _aquariumId == null
                    ? l10n.feedingHistoryAllAquariums
                    : aquariums.firstWhere((a) => a.id == _aquariumId).name,
              ),
              trailing: const Icon(Icons.expand_more),
              onTap: () async {
                final picked = await showFeedingHistoryAquariumPicker(
                  context,
                  aquariums: [
                    for (final a in aquariums)
                      AquariumPickerEntry(id: a.id, name: a.name),
                  ],
                  currentSelection: _aquariumId,
                );
                if (!mounted) return;
                setState(() => _aquariumId = picked);
                if (picked != null) {
                  AnalyticsService.instance.trackFeedingHistoryAquariumFiltered(
                    aquariumId: picked,
                    range: _range.name,
                  );
                }
              },
            ),
          SwitchListTile(
            value: _onlyMine,
            onChanged: (v) {
              setState(() => _onlyMine = v);
              AnalyticsService.instance.trackFeedingHistoryOnlyMineToggled(
                enabled: v,
                range: _range.name,
              );
            },
            title: Text(l10n.feedingHistoryShowOnlyMine),
          ),
          Expanded(
            child: asyncHistory.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (history) {
                if (history.totalFedCount == 0) {
                  return FeedingHistoryEmptyState(
                    onCtaTap: () => Navigator.of(context).maybePop(),
                  );
                }
                final timelineRows = _buildTimelineRows(history: history);
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 8),
                    FeedingHistoryHeatmap(days: history.days, onDayTap: (_) {}),
                    if (history.aquariumBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      FeedingHistoryAquariumStrip(
                        breakdown: history.aquariumBreakdown,
                        onChipTap: (id) => setState(() => _aquariumId = id),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FeedingHistoryInsightsRow(
                      totalFedCount: history.totalFedCount,
                      longestStreak: history.longestStreak,
                      bestDayOfWeek: history.bestDayOfWeek,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: FeedingHistoryTimeline(rows: timelineRows),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<FeedingHistoryTimelineRow> _buildTimelineRows({
    required FeedingHistory history,
  }) {
    final logsDs = ref.read(feedingLogLocalDataSourceProvider);
    final aqDs = ref.read(aquariumLocalDataSourceProvider);
    final fishDs = ref.read(fishLocalDataSourceProvider);

    final fromLocal = history.rangeStart;
    final toLocal = history.rangeEnd.add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );
    Iterable<FeedingLogModel> raw = logsDs.getByDateRange(fromLocal, toLocal);
    if (_aquariumId != null) {
      raw = raw.where((l) => l.aquariumId == _aquariumId);
    }
    if (_onlyMine) {
      final user = ref.read(currentUserProvider);
      raw = raw.where((l) => l.actedByUserId == user?.id);
    }
    final aquariumNames = {
      for (final a in aqDs.getAllAquariums()) a.id: a.name,
    };
    final fishNames = {
      for (final f in fishDs.getAllFish()) f.id: f.name ?? '—',
    };
    return [
      for (final log in raw)
        FeedingHistoryTimelineRow(
          log: log,
          aquariumName: aquariumNames[log.aquariumId] ?? '—',
          fishName: fishNames[log.fishId] ?? '—',
        ),
    ];
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.current, required this.onChanged});

  final FeedingHistoryRange current;
  final ValueChanged<FeedingHistoryRange> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        children: [
          for (final r in FeedingHistoryRange.values)
            ChoiceChip(
              label: Text(_label(l10n, r)),
              selected: current == r,
              onSelected: (_) => onChanged(r),
            ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, FeedingHistoryRange r) {
    switch (r) {
      case FeedingHistoryRange.sevenDays:
        return l10n.feedingHistoryRange7d;
      case FeedingHistoryRange.thirtyDays:
        return l10n.feedingHistoryRange30d;
      case FeedingHistoryRange.sixMonths:
        return l10n.feedingHistoryRange6m;
    }
  }
}
