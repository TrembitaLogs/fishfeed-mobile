import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/domain/entities/aquarium.dart';
import 'package:fishfeed/domain/entities/water_type.dart';
import 'package:fishfeed/l10n/app_localizations.dart';
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
  final _formKey = GlobalKey<FormState>();
  WaterType _selectedWaterType = WaterType.freshwater;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Restore previous name if going back
    final currentName = ref
        .read(onboardingNotifierProvider)
        .currentAquariumName;
    if (currentName != null) {
      _nameController.text = currentName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              createdAquariums.isEmpty
                  ? l10n.createYourFirstAquarium
                  : l10n.addAnotherAquarium,
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
            _WaterTypeSelector(
              selectedType: _selectedWaterType,
              onChanged: isCreating
                  ? null
                  : (type) => setState(() => _selectedWaterType = type),
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

/// Water type selector widget.
class _WaterTypeSelector extends StatelessWidget {
  const _WaterTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final WaterType selectedType;
  final ValueChanged<WaterType>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _WaterTypeOption(
            type: WaterType.freshwater,
            label: l10n.freshwater,
            icon: Icons.water_drop,
            isSelected: selectedType == WaterType.freshwater,
            onTap: onChanged != null
                ? () => onChanged!(WaterType.freshwater)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _WaterTypeOption(
            type: WaterType.saltwater,
            label: l10n.saltwater,
            icon: Icons.waves,
            isSelected: selectedType == WaterType.saltwater,
            onTap: onChanged != null
                ? () => onChanged!(WaterType.saltwater)
                : null,
          ),
        ),
      ],
    );
  }
}

/// Individual water type option card.
class _WaterTypeOption extends StatelessWidget {
  const _WaterTypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final WaterType type;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
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
