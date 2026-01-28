import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enum representing the tabs in the home screen bottom navigation.
enum HomeTab {
  home,
  calendar,
  profile,
}

/// Provider for managing the current selected tab index in HomeScreen.
///
/// Uses [StateProvider] for simple state management of the active tab.
///
/// Usage:
/// ```dart
/// // Read current tab
/// final currentTab = ref.watch(homeTabProvider);
///
/// // Change tab
/// ref.read(homeTabProvider.notifier).state = HomeTab.calendar;
/// ```
final homeTabProvider = StateProvider<HomeTab>((ref) {
  return HomeTab.home;
});
