import 'package:flutter/material.dart';

/// Progress dot indicator for onboarding steps.
class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(
          totalSteps,
          (index) => Expanded(
            child: _ProgressDot(
              isActive: index == currentStep,
              isCompleted: index < currentStep,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.isActive, required this.isCompleted});

  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 4,
        decoration: BoxDecoration(
          color: isActive || isCompleted
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Navigation buttons for onboarding (Back/Cancel + Next/Done).
class OnboardingNavigationButtons extends StatelessWidget {
  const OnboardingNavigationButtons({
    super.key,
    required this.isFirstStep,
    required this.isAddFlow,
    required this.isLoading,
    required this.canProceed,
    required this.nextButtonText,
    required this.onBack,
    required this.onCancel,
    required this.onNext,
  });

  final bool isFirstStep;
  final bool isAddFlow;
  final bool isLoading;
  final bool canProceed;
  final String nextButtonText;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (!isFirstStep)
            // Back button for non-first steps
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            )
          else if (isAddFlow)
            // Cancel button on first step in add mode
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: canProceed && !isLoading ? onNext : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: theme.colorScheme.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(nextButtonText),
            ),
          ),
        ],
      ),
    );
  }
}
