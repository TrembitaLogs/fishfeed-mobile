import 'package:fishfeed/domain/entities/species.dart';
import 'package:fishfeed/presentation/providers/onboarding_provider.dart';

/// Parameters for [GenerateScheduleUseCase].
class GenerateScheduleParams {
  const GenerateScheduleParams({
    required this.speciesSelections,
  });

  final List<SpeciesSelection> speciesSelections;
}

/// Use case for generating feeding schedule based on selected species.
///
/// Takes a list of species with quantities and generates an optimized
/// feeding schedule with times distributed evenly throughout the day.
class GenerateScheduleUseCase {
  const GenerateScheduleUseCase();

  /// First feeding time of the day (08:00).
  static const int firstFeedingHour = 8;

  /// Last feeding time of the day (20:00).
  static const int lastFeedingHour = 20;

  /// Executes the schedule generation.
  ///
  /// Algorithm:
  /// 1. For each species, determine feeding frequency
  /// 2. Calculate feeding times distributed evenly between 8:00 and 20:00
  /// 3. Return generated schedule entries
  List<GeneratedScheduleEntry> call(GenerateScheduleParams params) {
    if (params.speciesSelections.isEmpty) {
      return [];
    }

    return params.speciesSelections.map((selection) {
      final species = selection.species;
      final feedingCount = _getFeedingCount(species.feedingFrequency);
      final feedingTimes = _distributeFeedingTimes(feedingCount);
      final portionGrams = _calculatePortion(species, selection.quantity);

      return GeneratedScheduleEntry(
        speciesId: species.id,
        speciesName: species.name,
        feedingTimes: feedingTimes,
        foodType: species.foodType ?? FoodType.flakes,
        portionGrams: portionGrams,
      );
    }).toList();
  }

  /// Determines number of feedings per day based on frequency string.
  int _getFeedingCount(String? frequency) {
    return switch (frequency) {
      'twice_daily' => 2,
      'three_times_daily' => 3,
      'daily' => 1,
      'every_other_day' => 1,
      _ => 1,
    };
  }

  /// Distributes feeding times evenly between [firstFeedingHour] and [lastFeedingHour].
  ///
  /// Examples:
  /// - 1 feeding: 09:00 (middle of the day)
  /// - 2 feedings: 08:00, 18:00
  /// - 3 feedings: 08:00, 14:00, 20:00
  List<String> _distributeFeedingTimes(int count) {
    if (count <= 0) return ['09:00'];
    if (count == 1) return ['09:00'];

    final times = <String>[];
    const totalHours = lastFeedingHour - firstFeedingHour;
    final interval = totalHours / (count - 1);

    for (var i = 0; i < count; i++) {
      final hour = firstFeedingHour + (interval * i).round();
      times.add(_formatTime(hour, 0));
    }

    return times;
  }

  /// Calculates portion size based on species defaults and quantity.
  double _calculatePortion(Species species, int quantity) {
    final basePortion = species.defaultPortionGrams ?? _getDefaultPortion(species.portionHint);
    return basePortion * quantity;
  }

  /// Gets default portion in grams based on portion hint.
  double _getDefaultPortion(PortionHint? hint) {
    return switch (hint) {
      PortionHint.small => 0.3,
      PortionHint.medium => 0.5,
      PortionHint.large => 1.0,
      null => 0.5,
    };
  }

  /// Formats hour and minute into "HH:mm" string.
  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

/// Merged feeding time slot combining multiple species at the same time.
///
/// Used when multiple species have overlapping feeding times to create
/// a unified feeding event.
class MergedFeedingSlot {
  const MergedFeedingSlot({
    required this.time,
    required this.species,
  });

  /// Feeding time in "HH:mm" format.
  final String time;

  /// List of species to feed at this time with their portions.
  final List<FeedingSlotEntry> species;
}

/// Individual species entry within a merged feeding slot.
class FeedingSlotEntry {
  const FeedingSlotEntry({
    required this.speciesId,
    required this.speciesName,
    required this.foodType,
    required this.portionGrams,
  });

  final String speciesId;
  final String speciesName;
  final FoodType foodType;
  final double portionGrams;
}

/// Extension for creating merged feeding slots from schedule entries.
extension GenerateScheduleUseCaseX on GenerateScheduleUseCase {
  /// Merges schedule entries into unified time slots.
  ///
  /// Groups all species that need feeding at the same time into
  /// single [MergedFeedingSlot] objects for unified notifications.
  List<MergedFeedingSlot> mergeToTimeSlots(List<GeneratedScheduleEntry> schedule) {
    final timeSlotMap = <String, List<FeedingSlotEntry>>{};

    for (final entry in schedule) {
      for (final time in entry.feedingTimes) {
        final slotEntry = FeedingSlotEntry(
          speciesId: entry.speciesId,
          speciesName: entry.speciesName,
          foodType: entry.foodType,
          portionGrams: entry.portionGrams,
        );

        timeSlotMap.putIfAbsent(time, () => []).add(slotEntry);
      }
    }

    final slots = timeSlotMap.entries
        .map((e) => MergedFeedingSlot(time: e.key, species: e.value))
        .toList();

    // Sort by time
    slots.sort((a, b) => a.time.compareTo(b.time));

    return slots;
  }
}
