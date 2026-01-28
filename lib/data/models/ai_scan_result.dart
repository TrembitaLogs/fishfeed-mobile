import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_scan_result.freezed.dart';
part 'ai_scan_result.g.dart';

/// DTO for AI fish scan result from the API.
///
/// Contains the detected species information and AI recommendations.
@freezed
class AiScanResult with _$AiScanResult {
  const AiScanResult._();

  const factory AiScanResult({
    /// Unique identifier of the detected species.
    @JsonKey(name: 'species_id') required String speciesId,

    /// Common name of the detected species.
    @JsonKey(name: 'species_name') required String speciesName,

    /// Confidence score of the detection (0.0 to 1.0).
    required double confidence,

    /// AI-generated care recommendations for this species.
    @Default([]) List<String> recommendations,

    /// Optional image URL for the detected species.
    @JsonKey(name: 'image_url') String? imageUrl,

    /// Optional feeding frequency recommendation.
    @JsonKey(name: 'feeding_frequency') String? feedingFrequency,

    /// Optional care level (beginner, intermediate, advanced).
    @JsonKey(name: 'care_level') String? careLevel,
  }) = _AiScanResult;

  factory AiScanResult.fromJson(Map<String, dynamic> json) =>
      _$AiScanResultFromJson(json);

  /// Whether the confidence is high enough to auto-confirm.
  bool get isHighConfidence => confidence >= 0.8;

  /// Whether the confidence is too low for reliable detection.
  bool get isLowConfidence => confidence < 0.5;

  /// Confidence as a percentage string (e.g., "85%").
  String get confidencePercent => '${(confidence * 100).round()}%';
}
