import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fishfeed/core/utils/date_time_utils.dart';
import 'package:fishfeed/data/models/feeding_log_model.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

/// A single row of data to be rendered in the timeline.
class FeedingHistoryTimelineRow {
  const FeedingHistoryTimelineRow({
    required this.log,
    required this.aquariumName,
    required this.fishName,
  });

  final FeedingLogModel log;
  final String aquariumName;
  final String fishName;
}

/// A date-grouped scrollable timeline of feeding log entries.
///
/// Entries are sorted newest-first and separated by sticky date headers.
class FeedingHistoryTimeline extends StatelessWidget {
  const FeedingHistoryTimeline({super.key, required this.rows});

  final List<FeedingHistoryTimelineRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.yMMMMEEEEd(locale);
    final timeFmt = DateFormat.Hm(locale);
    final theme = Theme.of(context);

    // Sort newest-first.
    final sorted = [...rows]
      ..sort((a, b) => b.log.actedAt.compareTo(a.log.actedAt));

    // Group by local calendar day, preserving sorted order.
    final groups = <DateTime, List<FeedingHistoryTimelineRow>>{};
    for (final r in sorted) {
      final key = DateTimeUtils.startOfDay(r.log.actedAt.toLocal());
      groups.putIfAbsent(key, () => []).add(r);
    }

    final children = <Widget>[];
    for (final entry in groups.entries) {
      // Unique key per date so Flutter can distinguish headers.
      final headerKey = ValueKey(
        'feeding_history_timeline_date_header_${entry.key.toIso8601String()}',
      );

      children.add(
        Padding(
          key: headerKey,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            dateFmt.format(entry.key),
            style: theme.textTheme.titleSmall,
          ),
        ),
      );

      for (final row in entry.value) {
        final actor = row.log.actedByUserName;
        children.add(
          ListTile(
            dense: true,
            title: Text('${row.aquariumName} · ${row.fishName}'),
            subtitle: Text(
              '${timeFmt.format(row.log.actedAt.toLocal())}'
              '${actor == null ? '' : ' · $actor'}',
            ),
            trailing: Text(
              row.log.isFed
                  ? l10n.feedingHistoryActionFed
                  : l10n.feedingHistoryActionMissed,
              style: TextStyle(
                color: row.log.isFed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ),
        );
      }
    }

    return ListView(children: children);
  }
}
