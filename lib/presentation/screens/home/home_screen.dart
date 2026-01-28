import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fishfeed/l10n/app_localizations.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/presentation/providers/home_tab_provider.dart';
import 'package:fishfeed/presentation/router/app_router.dart';
import 'package:fishfeed/presentation/screens/calendar/calendar_screen.dart';
import 'package:fishfeed/presentation/screens/home/today_view.dart';
import 'package:fishfeed/presentation/screens/profile/profile_screen.dart';
import 'package:fishfeed/presentation/widgets/feeding/streak_badge.dart';
import 'package:fishfeed/presentation/widgets/sync_status_indicator.dart';

/// Main home screen with bottom navigation and tab content.
///
/// Features:
/// - AppBar with time-based greeting and streak badge placeholder
/// - Bottom navigation with Home, Calendar, Profile tabs
/// - FAB for adding new fish
/// - IndexedStack for preserving tab state
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(homeTabProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    final String userName;
    if (user != null) {
      userName = user.displayName ?? user.email.split('@').first;
    } else {
      userName = '';
    }
    final greeting = _getGreeting(userName);

    return Scaffold(
      appBar: AppBar(
        title: Text(greeting),
        actions: const [
          // Sync status indicator - shows sync state and last synced time
          SyncStatusIndicator(),
          SizedBox(width: 8),
          // Streak badge - provider will be connected in task 7.6
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: StreakBadge(streak: 0),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentTab.index,
        children: const [TodayView(), CalendarScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab.index,
        onDestinationSelected: (index) {
          ref.read(homeTabProvider.notifier).state = HomeTab.values[index];
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddFishPressed(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Returns a time-based greeting message.
  String _getGreeting(String userName) {
    final hour = DateTime.now().hour;
    final String timeGreeting;

    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 18) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    if (userName.isEmpty) {
      return timeGreeting;
    }

    return '$timeGreeting, $userName!';
  }

  Future<void> _onAddFishPressed(BuildContext context) async {
    final l = AppLocalizations.of(context)!;

    // Show bottom sheet to choose add method
    final choice = await showModalBottomSheet<_AddFishChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l.scanWithAiCamera),
              subtitle: Text(l.takePhotoToIdentify),
              onTap: () => Navigator.pop(ctx, _AddFishChoice.aiCamera),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(l.selectFromList),
              subtitle: Text(l.chooseFromSpeciesList),
              onTap: () => Navigator.pop(ctx, _AddFishChoice.manual),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    switch (choice) {
      case _AddFishChoice.aiCamera:
        context.push(AppRouter.aiCamera);
        break;
      case _AddFishChoice.manual:
        context.push(AppRouter.addFish);
        break;
    }
  }
}

/// Choice for adding fish method.
enum _AddFishChoice { aiCamera, manual }
