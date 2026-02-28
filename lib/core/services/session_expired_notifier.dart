import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signals that the user session has expired (both tokens invalid).
///
/// Set to `true` by [TokenRefreshInterceptor] via [ApiClient.onLogout].
/// Consumed by [AuthStateListenable] to trigger redirect to login screen.
///
/// This provider exists to break the circular dependency between
/// [apiClientProvider] and [authNotifierProvider].
final sessionExpiredProvider = StateProvider<bool>((ref) => false);
