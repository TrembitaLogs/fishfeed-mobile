import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fishfeed/data/models/ai_scan_result.dart';
import 'package:fishfeed/presentation/widgets/confidence_indicator.dart';

/// Result returned from ScanResultScreen when user confirms the detection.
class ScanConfirmResult {
  const ScanConfirmResult({
    required this.speciesId,
    required this.speciesName,
    this.recommendations = const [],
  });

  /// ID of the confirmed species.
  final String speciesId;

  /// Name of the confirmed species.
  final String speciesName;

  /// AI recommendations for this species.
  final List<String> recommendations;
}

/// Screen displaying AI scan results with confirm/edit options.
///
/// Shows the captured image, detected species, confidence score,
/// and provides options to confirm or edit the detection.
///
/// Navigation results:
/// - Confirm: Returns [ScanConfirmResult] with species info
/// - Edit: Returns `null` with `editRequested: true` flag via callback
/// - Back: Returns `null`
class ScanResultScreen extends ConsumerStatefulWidget {
  const ScanResultScreen({
    super.key,
    required this.result,
    required this.imageBytes,
    this.onEditRequested,
  });

  /// The AI scan result to display.
  final AiScanResult result;

  /// The captured image bytes.
  final Uint8List imageBytes;

  /// Callback when user wants to manually edit/select species.
  final VoidCallback? onEditRequested;

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    Navigator.of(context).pop(
      ScanConfirmResult(
        speciesId: widget.result.speciesId,
        speciesName: widget.result.speciesName,
        recommendations: widget.result.recommendations,
      ),
    );
  }

  void _onEdit() {
    widget.onEditRequested?.call();
    Navigator.of(context).pop();
  }

  void _onBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLowConfidence = widget.result.isLowConfidence;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with gradient overlay
          _buildBackgroundImage(),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),

                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 16),

                        // Result card with fade animation
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildResultCard(context, isLowConfidence),
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildActionButtons(context, isLowConfidence),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          widget.imageBytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade900,
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white38,
                size: 64,
              ),
            ),
          ),
        ),
        // Gradient overlay for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.5, 0.8],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            iconSize: 28,
            onPressed: _onBack,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.amber,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'AI Result',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, bool isLowConfidence) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Low confidence warning banner
          if (isLowConfidence) _buildWarningBanner(context),

          // Confidence indicator
          ConfidenceIndicator(
            confidence: widget.result.confidence,
            size: 120,
            strokeWidth: 10,
          ),

          const SizedBox(height: 20),

          // Species name
          Text(
            widget.result.speciesName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Species ID badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ID: ${widget.result.speciesId}',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Recommendations
          if (widget.result.recommendations.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRecommendations(context),
          ],

          // Additional info
          if (widget.result.careLevel != null ||
              widget.result.feedingFrequency != null) ...[
            const SizedBox(height: 16),
            _buildAdditionalInfo(context),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Low confidence. Please verify or select manually.',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Recommendations',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.result.recommendations.take(3).map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.result.careLevel != null) ...[
          _buildInfoChip(
            context,
            Icons.spa_outlined,
            _formatCareLevel(widget.result.careLevel!),
            colorScheme.secondary,
          ),
        ],
        if (widget.result.careLevel != null &&
            widget.result.feedingFrequency != null)
          const SizedBox(width: 12),
        if (widget.result.feedingFrequency != null) ...[
          _buildInfoChip(
            context,
            Icons.schedule_outlined,
            _formatFeedingFrequency(widget.result.feedingFrequency!),
            colorScheme.tertiary,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCareLevel(String level) {
    return switch (level.toLowerCase()) {
      'beginner' => 'Beginner',
      'intermediate' => 'Intermediate',
      'advanced' => 'Advanced',
      _ => level,
    };
  }

  String _formatFeedingFrequency(String frequency) {
    return switch (frequency.toLowerCase()) {
      'once_daily' => 'Once daily',
      'twice_daily' => 'Twice daily',
      'daily' => 'Daily',
      'every_other_day' => 'Every other day',
      _ => frequency.replaceAll('_', ' '),
    };
  }

  Widget _buildActionButtons(BuildContext context, bool isLowConfidence) {
    final colorScheme = Theme.of(context).colorScheme;

    // For low confidence, Edit button should be more prominent
    if (isLowConfidence) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Primary: Edit button (more prominent for low confidence)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Select Manually'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary: Confirm button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _onConfirm,
                icon: const Icon(Icons.check),
                label: const Text('Confirm Anyway'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white38),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal flow: Confirm is primary, Edit is secondary
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Edit button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Not correct?'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Confirm button
          Expanded(
            child: FilledButton.icon(
              onPressed: _onConfirm,
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
