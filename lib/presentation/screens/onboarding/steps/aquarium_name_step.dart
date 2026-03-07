import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/aquarium_providers.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';

/// Step 0: Create aquarium with name input.
///
/// First step in the aquarium-first onboarding flow.
/// User enters aquarium name and optionally selects water type.
/// On "Next" - creates aquarium via API and stores UUID in state.
class AquariumNameStep extends ConsumerStatefulWidget {
  const AquariumNameStep({super.key});

  @override
  ConsumerState<AquariumNameStep> createState() => _AquariumNameStepState();
}

class _AquariumNameStepState extends ConsumerState<AquariumNameStep> {
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Restore previous values if going back
    final state = ref.read(onboardingNotifierProvider);
    if (state.currentAquariumName != null) {
      _nameController.text = state.currentAquariumName!;
    }
    if (state.currentCapacity != null) {
      _capacityController.text =
          state.currentCapacity! == state.currentCapacity!.roundToDouble()
          ? state.currentCapacity!.toInt().toString()
          : state.currentCapacity!.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    // Update state for canProceed check
    ref.read(onboardingNotifierProvider.notifier).setAquariumName(value);
    // Clear error when user types
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _onCapacityChanged(String value) {
    final parsed = value.trim().isNotEmpty
        ? double.tryParse(value.trim())
        : null;
    ref.read(onboardingNotifierProvider.notifier).setCapacity(parsed);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.fieldRequired;
    }
    if (value.trim().length > 50) {
      return AppLocalizations.of(context)!.aquariumNameTooLong;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCreating = ref.watch(isCreatingAquariumProvider);
    final createdAquariums = ref.watch(createdAquariumsProvider);
    final existingAquariums = ref.watch(aquariumsListProvider);
    final selectedWaterType = ref.watch(
      onboardingNotifierProvider.select((s) => s.currentWaterType),
    );

    // Show "Add Another" if user has existing aquariums or created some this session
    final hasAquariums =
        existingAquariums.isNotEmpty || createdAquariums.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              hasAquariums
                  ? l10n.addAnotherAquarium
                  : l10n.createYourFirstAquarium,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aquariumNameDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Aquarium name input
            Text(
              l10n.aquariumName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              onChanged: _onNameChanged,
              validator: _validateName,
              enabled: !isCreating,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.aquariumNameHint,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: const Icon(Icons.water_drop_outlined),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Water type selection
            Text(
              l10n.waterType,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<WaterType>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: WaterType.freshwater,
                    label: Text(l10n.freshwater),
                  ),
                  ButtonSegment(
                    value: WaterType.saltwater,
                    label: Text(l10n.saltwater),
                  ),
                  ButtonSegment(
                    value: WaterType.brackish,
                    label: Text(l10n.brackish),
                  ),
                ],
                selected: {selectedWaterType},
                onSelectionChanged: isCreating
                    ? null
                    : (selected) => ref
                          .read(onboardingNotifierProvider.notifier)
                          .setWaterType(selected.first),
              ),
            ),

            const SizedBox(height: 24),

            // Volume (capacity)
            Text(
              l10n.volume,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _capacityController,
              onChanged: _onCapacityChanged,
              enabled: !isCreating,
              decoration: InputDecoration(
                hintText: l10n.volume,
                suffixText: 'L',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),

            // Info about created aquariums
            if (createdAquariums.isNotEmpty) ...[
              const SizedBox(height: 24),
              _CreatedAquariumsSummary(aquariums: createdAquariums),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Summary of already created aquariums during this onboarding session.
class _CreatedAquariumsSummary extends StatelessWidget {
  const _CreatedAquariumsSummary({required this.aquariums});

  final List<Aquarium> aquariums;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.aquariumsCreated(aquariums.length),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...aquariums.map(
            (aquarium) => Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                '• ${aquarium.name}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
