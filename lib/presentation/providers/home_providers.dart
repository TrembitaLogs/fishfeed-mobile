import 'package:flutter_riverpod/flutter_riverpod.dart';

// Re-export home tab provider for convenience
export 'home_tab_provider.dart';

/// Time period of the day for greeting messages.
enum TimePeriod {
  morning,
  afternoon,
  evening,
  night,
}

/// Greeting data including message and time period.
class GreetingData {
  const GreetingData({
    required this.greeting,
    required this.timePeriod,
    required this.emoji,
  });

  /// The greeting message.
  final String greeting;

  /// Current time period.
  final TimePeriod timePeriod;

  /// Emoji for the time period.
  final String emoji;
}

/// Provider for greeting based on current time of day.
///
/// Returns appropriate greeting message:
/// - 00:00-05:59: "Good night"
/// - 06:00-11:59: "Good morning"
/// - 12:00-17:59: "Good afternoon"
/// - 18:00-23:59: "Good evening"
///
/// Usage:
/// ```dart
/// final greeting = ref.watch(greetingProvider);
/// Text('${greeting.emoji} ${greeting.greeting}');
/// ```
final greetingProvider = Provider<GreetingData>((ref) {
  final hour = DateTime.now().hour;

  if (hour >= 6 && hour < 12) {
    return const GreetingData(
      greeting: 'Good morning',
      timePeriod: TimePeriod.morning,
      emoji: '\u{1F31E}', // Sun with face
    );
  } else if (hour >= 12 && hour < 18) {
    return const GreetingData(
      greeting: 'Good afternoon',
      timePeriod: TimePeriod.afternoon,
      emoji: '\u{2600}', // Sun
    );
  } else if (hour >= 18 && hour < 22) {
    return const GreetingData(
      greeting: 'Good evening',
      timePeriod: TimePeriod.evening,
      emoji: '\u{1F319}', // Crescent moon
    );
  } else {
    return const GreetingData(
      greeting: 'Good night',
      timePeriod: TimePeriod.night,
      emoji: '\u{1F31B}', // First quarter moon with face
    );
  }
});

/// Provider for just the greeting message string.
///
/// Convenience provider for widgets that only need the text.
final greetingMessageProvider = Provider<String>((ref) {
  return ref.watch(greetingProvider).greeting;
});

/// Provider for greeting with user's name.
///
/// Returns a personalized greeting like "Good morning, John!"
/// Falls back to just the greeting if user name is not available.
final personalizedGreetingProvider = Provider.family<String, String?>((ref, userName) {
  final greeting = ref.watch(greetingProvider).greeting;

  if (userName != null && userName.isNotEmpty) {
    return '$greeting, $userName!';
  }
  return '$greeting!';
});
