import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Environment variable keys for Sentry configuration.
abstract final class SentryEnvKeys {
  static const String dsn = 'SENTRY_DSN';
}

/// Service for error tracking and performance monitoring with Sentry.
///
/// Provides a wrapper around Sentry SDK with additional context
/// and user information for better error debugging.
class SentryService {
  SentryService._();

  static final SentryService _instance = SentryService._();

  /// Singleton instance of SentryService.
  static SentryService get instance => _instance;

  bool _isInitialized = false;

  /// Whether Sentry has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes Sentry SDK with the provided [appRunner].
  ///
  /// Must be called before runApp() in main.dart.
  /// Uses DSN from environment variables.
  /// Skips initialization if DSN is not provided.
  Future<void> initialize({required Future<void> Function() appRunner}) async {
    final dsn = dotenv.env[SentryEnvKeys.dsn];

    // Skip initialization if DSN is not configured
    if (dsn == null || dsn.isEmpty) {
      if (kDebugMode) {
        debugPrint('[Sentry] DSN not configured, skipping initialization');
      }
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;

        // Environment configuration
        options.environment = kDebugMode ? 'development' : 'production';

        // Performance monitoring
        // 100% of transactions in development, 20% in production
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;

        // Session tracking
        options.enableAutoSessionTracking = true;

        // Breadcrumbs configuration
        options.enableAutoNativeBreadcrumbs = true;
        options.maxBreadcrumbs = 100;

        // Attach thread info to events
        options.attachThreads = true;

        // Capture failed HTTP requests
        options.captureFailedRequests = true;

        // Enable debug logging only in debug mode
        options.debug = kDebugMode;

        // Send default PII (IP address)
        options.sendDefaultPii = false;

        // Before send callback for filtering or modifying events
        options.beforeSend = _beforeSend;
      },
      appRunner: appRunner,
    );

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('[Sentry] Initialized successfully');
    }
  }

  /// Callback executed before sending events to Sentry.
  ///
  /// Can be used to filter out certain events or add additional context.
  SentryEvent? _beforeSend(SentryEvent event, Hint hint) {
    // Filter out events in debug mode if needed
    // For now, send all events
    return event;
  }

  /// Sets user information for Sentry events.
  ///
  /// Call this after user authentication to associate errors with users.
  Future<void> setUser({
    required String userId,
    String? email,
    String? username,
    Map<String, String>? extras,
  }) async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: userId,
        email: email,
        username: username,
        data: extras,
      ));
    });

    if (kDebugMode) {
      debugPrint('[Sentry] User set: $userId');
    }
  }

  /// Clears user information from Sentry.
  ///
  /// Call this on logout.
  Future<void> clearUser() async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setUser(null);
    });

    if (kDebugMode) {
      debugPrint('[Sentry] User cleared');
    }
  }

  /// Captures an exception with optional stack trace and additional context.
  ///
  /// Use this method to manually capture exceptions that are handled
  /// but should be tracked in Sentry.
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extras,
    SentryLevel? level,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint('[Sentry] Not initialized, logging exception: $exception');
      }
      return;
    }

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (message != null) {
          scope.setContexts('Additional Info', {'message': message});
        }
        if (extras != null) {
          scope.setContexts('Extra Data', extras);
        }
        if (level != null) {
          scope.level = level;
        }
      },
    );

    if (kDebugMode) {
      debugPrint('[Sentry] Exception captured: $exception');
    }
  }

  /// Captures a message for informational purposes.
  ///
  /// Use for important events that aren't exceptions but should be tracked.
  Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint('[Sentry] Not initialized, logging message: $message');
      }
      return;
    }

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: extras != null
          ? (scope) {
              scope.setContexts('Extra Data', extras);
            }
          : null,
    );

    if (kDebugMode) {
      debugPrint('[Sentry] Message captured: $message');
    }
  }

  /// Adds a breadcrumb for debugging context.
  ///
  /// Breadcrumbs are included in error reports to show what happened
  /// before an error occurred.
  Future<void> addBreadcrumb({
    required String message,
    String? category,
    String? type,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized) return;

    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        type: type,
        level: level,
        data: data,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  /// Sets a tag that will be attached to all subsequent events.
  Future<void> setTag(String key, String value) async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Sets extra context data that will be attached to all events.
  Future<void> setContext(String key, Map<String, dynamic> value) async {
    if (!_isInitialized) return;

    await Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// Starts a performance transaction.
  ///
  /// Returns a transaction that can be used to measure performance.
  /// Remember to call [finishTransaction] when the operation is complete.
  ISentrySpan? startTransaction({
    required String name,
    required String operation,
    String? description,
  }) {
    if (!_isInitialized) return null;

    final transaction = Sentry.startTransaction(
      name,
      operation,
      description: description,
      bindToScope: true,
    );

    return transaction;
  }
}

/// Provider for the SentryService singleton.
final sentryServiceProvider = Provider<SentryService>((ref) {
  return SentryService.instance;
});
