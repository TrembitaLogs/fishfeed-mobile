import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/domain/usecases/generate_schedule_usecase.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';

/// Step 3: Schedule preview and confirmation.
///
/// Shows auto-generated feeding schedule based on species selections.
/// Displays summary with total fish count and daily feedings.
/// Allows user to edit feeding times before completing onboarding.
class SchedulePreviewStep extends ConsumerStatefulWidget {
  const SchedulePreviewStep({super.key});

  @override
  ConsumerState<SchedulePreviewStep> createState() =>
      _SchedulePreviewStepState();
}

class _SchedulePreviewStepState extends ConsumerState<SchedulePreviewStep> {
  @override
  void initState() {
    super.initState();
    // Generate schedule when step is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateSchedule();
    });
  }

  void _generateSchedule() {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final state = ref.read(onboardingNotifierProvider);

    // Skip if schedule already generated
    if (state.generatedSchedule.isNotEmpty) return;

    final selectedSpecies = state.selectedSpecies;
    notifier.setGeneratingSchedule(true);

    // Use the GenerateScheduleUseCase for schedule generation
    const usecase = GenerateScheduleUseCase();
    final schedule = usecase(
      GenerateScheduleParams(speciesSelections: selectedSpecies),
    );

    notifier.setGeneratedSchedule(schedule);
  }

  Future<void> _showTimePicker(
    BuildContext context,
    String speciesId,
    int timeIndex,
    String currentTime,
  ) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null && mounted) {
      final formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      ref
          .read(onboardingNotifierProvider.notifier)
          .updateFeedingTime(speciesId, timeIndex, formattedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingNotifierProvider);

    // Calculate summary data
    final totalFish = state.selectedSpecies.fold<int>(
      0,
      (sum, selection) => sum + selection.quantity,
    );
    final totalFeedingsPerDay = state.generatedSchedule.fold<int>(
      0,
      (sum, entry) => sum + entry.feedingTimes.length,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Your feeding schedule',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve created a schedule based on your fish',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!state.isGeneratingSchedule && state.generatedSchedule.isNotEmpty)
            _SummaryCard(
              totalFish: totalFish,
              feedingsPerDay: totalFeedingsPerDay,
            ),
          const SizedBox(height: 16),
          if (state.isGeneratingSchedule)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.separated(
                itemCount: state.generatedSchedule.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final entry = state.generatedSchedule[index];
                  return _ScheduleCard(
                    entry: entry,
                    onEditTime: (timeIndex, currentTime) => _showTimePicker(
                      context,
                      entry.speciesId,
                      timeIndex,
                      currentTime,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Summary card showing total fish and feedings per day.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalFish, required this.feedingsPerDay});

  final int totalFish;
  final int feedingsPerDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                icon: Icons.pets,
                value: '$totalFish',
                label: totalFish == 1 ? 'fish' : 'fish',
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.2,
              ),
            ),
            Expanded(
              child: _SummaryItem(
                icon: Icons.schedule,
                value: '$feedingsPerDay',
                label: feedingsPerDay == 1 ? 'feeding/day' : 'feedings/day',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual summary item widget.
class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Schedule card for a single species.
class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.entry, required this.onEditTime});

  final GeneratedScheduleEntry entry;
  final void Function(int timeIndex, String currentTime) onEditTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  radius: 20,
                  child: Icon(
                    Icons.pets,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.speciesName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _EditableFeedingTimes(
              feedingTimes: entry.feedingTimes,
              onEditTime: onEditTime,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.restaurant,
              label: 'Food type',
              value: _formatFoodType(entry.foodType),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.scale,
              label: 'Portion',
              value: '${entry.portionGrams.toStringAsFixed(1)}g',
            ),
          ],
        ),
      ),
    );
  }

  String _formatFoodType(FoodType type) {
    return switch (type) {
      FoodType.flakes => 'Flakes',
      FoodType.pellets => 'Pellets',
      FoodType.live => 'Live food',
      FoodType.frozen => 'Frozen',
      FoodType.mixed => 'Mixed',
    };
  }
}

/// Editable feeding times row with tap-to-edit functionality.
class _EditableFeedingTimes extends StatelessWidget {
  const _EditableFeedingTimes({
    required this.feedingTimes,
    required this.onEditTime,
  });

  final List<String> feedingTimes;
  final void Function(int timeIndex, String currentTime) onEditTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          'Feeding times: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        ...feedingTimes.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0)
                Text(
                  ' & ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              InkWell(
                onTap: () => onEditTime(index, time),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

/// Info row for displaying schedule details.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
