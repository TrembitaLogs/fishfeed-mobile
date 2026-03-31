import 'package:flutter/material.dart';

import 'package:fishfeed/l10n/app_localizations.dart';

/// Dropdown for selecting the food type.
class EditFishFoodTypeDropdown extends StatelessWidget {
  const EditFishFoodTypeDropdown({
    super.key,
    required this.selectedFoodType,
    required this.foodTypes,
    required this.onChanged,
  });

  final String selectedFoodType;
  final List<String> foodTypes;
  final ValueChanged<String?> onChanged;

  String _localizedFoodType(AppLocalizations l, String type) {
    switch (type) {
      case 'flakes':
        return l.foodTypeFlakes;
      case 'pellets':
        return l.foodTypePellets;
      case 'frozen':
        return l.foodTypeFrozen;
      case 'live':
        return l.foodTypeLive;
      case 'mixed':
        return l.foodTypeMixed;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.foodType,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedFoodType,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.restaurant),
            border: OutlineInputBorder(),
          ),
          items: foodTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(_localizedFoodType(l, type)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Text field for portion hint.
class EditFishPortionHintField extends StatelessWidget {
  const EditFishPortionHintField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.portionHintLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lightbulb_outline),
            hintText: l.portionHintPlaceholder,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

/// Selector for feeding interval (daily, every other day, weekly).
class EditFishIntervalSelector extends StatelessWidget {
  const EditFishIntervalSelector({
    super.key,
    required this.selectedIntervalDays,
    required this.onChanged,
  });

  final int selectedIntervalDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.feedingInterval,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 1, label: Text(l.intervalDaily)),
              ButtonSegment(value: 2, label: Text(l.everyOtherDay)),
              ButtonSegment(value: 7, label: Text(l.intervalWeekly)),
            ],
            selected: {selectedIntervalDays},
            onSelectionChanged: (selected) => onChanged(selected.first),
          ),
        ),
      ],
    );
  }
}

/// Section for managing feeding times.
class EditFishFeedingTimesSection extends StatelessWidget {
  const EditFishFeedingTimesSection({
    super.key,
    required this.times,
    required this.onAddTime,
    required this.onRemoveTime,
  });

  final List<String> times;
  final VoidCallback onAddTime;
  final ValueChanged<String> onRemoveTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.feedingTimes,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: onAddTime,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.addFeedingTime),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (times.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '—',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times.map((time) {
              return Chip(
                avatar: Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                label: Text(time),
                onDeleted: () => onRemoveTime(time),
                deleteIconColor: theme.colorScheme.onSurfaceVariant,
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              );
            }).toList(),
          ),
      ],
    );
  }
}
