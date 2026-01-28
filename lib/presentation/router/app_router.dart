import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:fishfeed/core/config/animation_config.dart';
import 'package:fishfeed/presentation/providers/auth_provider.dart';
import 'package:fishfeed/services/sentry/sentry_service.dart';
import 'package:fishfeed/presentation/screens/auth/auth.dart';
import 'package:fishfeed/presentation/screens/calendar/calendar_screen.dart';
import 'package:fishfeed/presentation/screens/home/home.dart';
import 'package:fishfeed/presentation/screens/onboarding/onboarding.dart';
import 'package:fishfeed/presentation/screens/paywall/paywall.dart';
import 'package:fishfeed/presentation/screens/profile/profile.dart';
import 'package:fishfeed/presentation/screens/family/join_family_screen.dart';
import 'package:fishfeed/presentation/screens/settings/family_screen.dart';
import 'package:fishfeed/presentation/screens/settings/appearance_screen.dart';
import 'package:fishfeed/presentation/screens/settings/notification_settings_screen.dart';
import 'package:fishfeed/presentation/screens/settings/settings_screen.dart';
import 'package:fishfeed/presentation/screens/ai_camera/ai_camera_screen.dart';
import 'package:fishfeed/presentation/screens/aquarium/aquarium.dart';

/// Application router configuration using GoRouter.
///
/// Handles all navigation routes with authentication redirect logic.
/// Uses [AuthStateListenable] as refreshListenable for reactive route updates.
class AppRouter {
  AppRouter._();

  /// Route path constants.
  static const String auth = '/auth';
  static const String register = '/auth/register';
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String calendar = '/calendar';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notificationSettings = '/settings/notifications';
  static const String appearanceSettings = '/settings/appearance';
  static const String family = '/family/:aquariumId';
  static const String joinFamily = '/join/:inviteCode';
  static const String paywall = '/paywall';
  static const String aiCamera = '/ai-camera';
  static const String myAquarium = '/aquarium';
  static const String editFish = '/aquarium/fish/:fishId/edit';
  static const String addFish = '/add-fish';
  static const String addAquarium = '/add-aquarium';
  static const String editAquarium = '/aquarium/:aquariumId/edit';

  /// Creates a GoRouter instance with the provided [AuthStateListenable].
  ///
  /// The router will automatically re-evaluate routes when auth state changes.
  static GoRouter createRouter(AuthStateListenable authStateListenable) {
    return GoRouter(
      initialLocation: home,
      debugLogDiagnostics: true,
      refreshListenable: authStateListenable,
      redirect: (context, state) => _redirect(state, authStateListenable),
      routes: _routes,
      observers: _createObservers(),
    );
  }

  /// Creates navigation observers for the router.
  ///
  /// Includes Sentry observer for navigation breadcrumbs and performance tracing.
  static List<NavigatorObserver> _createObservers() {
    final observers = <NavigatorObserver>[];

    // Add Sentry observer if initialized
    if (SentryService.instance.isInitialized) {
      observers.add(
        SentryNavigatorObserver(
          enableAutoTransactions: true,
          setRouteNameAsTransaction: true,
          autoFinishAfter: const Duration(seconds: 3),
        ),
      );
    }

    return observers;
  }

  /// Redirect logic for authentication.
  ///
  /// - Unauthenticated users are redirected to [auth]
  /// - Authenticated users without onboarding go to [onboarding]
  /// - Authenticated users with onboarding can access all routes
  static String? _redirect(GoRouterState state, AuthStateListenable authState) {
    final isLoggedIn = authState.isLoggedIn;
    final hasCompletedOnboarding = authState.hasCompletedOnboarding;
    final currentPath = state.matchedLocation;

    // Public routes that don't require authentication
    final isAuthRoute = currentPath == auth || currentPath == register;
    final isOnboardingRoute = currentPath == onboarding;
    final isJoinRoute = currentPath.startsWith('/join/');

    // Not logged in
    if (!isLoggedIn) {
      // Allow staying on auth pages (login/register)
      if (isAuthRoute) return null;
      // Allow join route - it will handle auth requirement itself
      if (isJoinRoute) return null;
      // Redirect to auth for all other routes
      return auth;
    }

    // Logged in but hasn't completed onboarding
    if (!hasCompletedOnboarding) {
      // Allow staying on onboarding page
      if (isOnboardingRoute) return null;
      // Redirect to onboarding (except from auth)
      if (isAuthRoute) return onboarding;
      return onboarding;
    }

    // Logged in and completed onboarding - redirect away from auth/onboarding
    if (isAuthRoute || isOnboardingRoute) {
      return home;
    }

    // No redirect needed
    return null;
  }

  /// All application routes.
  static final List<RouteBase> _routes = [
    GoRoute(
      path: home,
      name: 'home',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: auth,
      name: 'auth',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const LoginScreen(),
        transitionType: _PageTransitionType.fade,
      ),
    ),
    GoRoute(
      path: register,
      name: 'register',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const RegisterScreen(),
        transitionType: _PageTransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: onboarding,
      name: 'onboarding',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const OnboardingScreen(),
        transitionType: _PageTransitionType.fade,
      ),
    ),
    GoRoute(
      path: calendar,
      name: 'calendar',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const Scaffold(body: CalendarScreen()),
      ),
    ),
    GoRoute(
      path: profile,
      name: 'profile',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: settings,
      name: 'settings',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const SettingsScreen(),
        transitionType: _PageTransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: notificationSettings,
      name: 'notificationSettings',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const NotificationSettingsScreen(),
        transitionType: _PageTransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: appearanceSettings,
      name: 'appearanceSettings',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const AppearanceScreen(),
        transitionType: _PageTransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: family,
      name: 'family',
      pageBuilder: (context, state) {
        final aquariumId = state.pathParameters['aquariumId']!;
        final aquariumName = state.uri.queryParameters['name'];
        return _buildPage(
          state: state,
          child: FamilyScreen(
            aquariumId: aquariumId,
            aquariumName: aquariumName,
          ),
          transitionType: _PageTransitionType.slideRight,
        );
      },
    ),
    GoRoute(
      path: joinFamily,
      name: 'joinFamily',
      pageBuilder: (context, state) {
        final inviteCode = state.pathParameters['inviteCode']!;
        return _buildPage(
          state: state,
          child: JoinFamilyScreen(inviteCode: inviteCode),
          transitionType: _PageTransitionType.slideUp,
        );
      },
    ),
    GoRoute(
      path: paywall,
      name: 'paywall',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const PaywallScreen(),
        transitionType: _PageTransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: aiCamera,
      name: 'aiCamera',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const AICameraScreen(),
        transitionType: _PageTransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: myAquarium,
      name: 'myAquarium',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const MyAquariumScreen(),
        transitionType: _PageTransitionType.slideRight,
      ),
    ),
    GoRoute(
      path: editFish,
      name: 'editFish',
      pageBuilder: (context, state) {
        final fishId = state.pathParameters['fishId']!;
        return _buildPage(
          state: state,
          child: EditFishScreen(fishId: fishId),
          transitionType: _PageTransitionType.slideRight,
        );
      },
    ),
    GoRoute(
      path: addFish,
      name: 'addFish',
      pageBuilder: (context, state) {
        final aquariumId = state.uri.queryParameters['aquariumId'];
        return _buildPage(
          state: state,
          child: OnboardingScreen(isAddMode: true, aquariumId: aquariumId),
          transitionType: _PageTransitionType.slideUp,
        );
      },
    ),
    GoRoute(
      path: addAquarium,
      name: 'addAquarium',
      pageBuilder: (context, state) => _buildPage(
        state: state,
        child: const OnboardingScreen(isAddAquariumMode: true),
        transitionType: _PageTransitionType.slideUp,
      ),
    ),
    GoRoute(
      path: editAquarium,
      name: 'editAquarium',
      pageBuilder: (context, state) {
        final aquariumId = state.pathParameters['aquariumId']!;
        return _buildPage(
          state: state,
          child: AquariumEditScreen(aquariumId: aquariumId),
          transitionType: _PageTransitionType.slideRight,
        );
      },
    ),
  ];

  /// Builds a custom page with animated transitions.
  static CustomTransitionPage<void> _buildPage({
    required GoRouterState state,
    required Widget child,
    _PageTransitionType transitionType = _PageTransitionType.fade,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AnimationConfig.pageTransitionDuration,
      reverseTransitionDuration: AnimationConfig.pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return switch (transitionType) {
          _PageTransitionType.fade => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AnimationConfig.pageTransitionCurve,
              ),
              child: child,
            ),
          _PageTransitionType.slideRight => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: AnimationConfig.pageTransitionCurve,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
          _PageTransitionType.slideUp => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: AnimationConfig.pageTransitionCurve,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
        };
      },
    );
  }
}

/// Page transition types.
enum _PageTransitionType {
  /// Fade in/out transition.
  fade,

  /// Slide from right transition.
  slideRight,

  /// Slide from bottom transition.
  slideUp,
}

/// Temporary placeholder screen for router setup.
///
/// Will be replaced with actual screens in subsequent tasks.
@visibleForTesting
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForTitle(title),
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'FishFeed - $title',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Screen placeholder',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    return switch (title) {
      'Home' => Icons.home,
      'Auth' => Icons.login,
      'Onboarding' => Icons.start,
      'Calendar' => Icons.calendar_month,
      'Profile' => Icons.person,
      'Settings' => Icons.settings,
      _ => Icons.pages,
    };
  }
}
