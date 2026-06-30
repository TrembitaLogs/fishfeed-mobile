import 'package:dio/dio.dart';
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

    await SentryFlutter.init((options) {
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

      // Strip credentials from breadcrumbs at capture time as defense in depth.
      options.beforeBreadcrumb = _beforeBreadcrumb;
    }, appRunner: appRunner);

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('[Sentry] Initialized successfully');
    }
  }

  /// HTTP paths whose request/response bodies must never reach Sentry.
  ///
  /// Matched as case-insensitive substring against the request URL.
  static const List<String> _sensitivePathFragments = ['/auth/', '/password'];

  /// Header names whose values are stripped from every captured event.
  ///
  /// Matched case-insensitively.
  static const List<String> _sensitiveHeaderNames = [
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
  ];

  /// Breadcrumb data keys that hold request/response bodies and must be
  /// redacted whenever the breadcrumb URL points at a sensitive path.
  static const List<String> _sensitiveBreadcrumbBodyKeys = [
    'request_body',
    'response_body',
    'data',
  ];

  static const String _redactedPlaceholder = '<redacted>';

  /// Callback executed before sending events to Sentry.
  ///
  /// Strips credentials and bodies of auth-related requests so that failed
  /// login/refresh/password-change calls do not exfiltrate plaintext
  /// passwords or tokens, then downgrades transient, app-handled /sync 5xx
  /// errors so they do not drown real crashes in noise.
  SentryEvent? _beforeSend(SentryEvent event, Hint hint) {
    final redacted = redactSensitiveData(event);
    return reclassifyTransientSyncErrors(redacted);
  }

  /// HTTP status codes for transient sync failures the app handles gracefully
  /// (retry / offline queue) and that should not be high-severity Sentry
  /// issues on their own.
  static const Set<int> _transientSyncStatusCodes = {502, 503, 504};

  /// Stable fingerprint that collapses transient /sync 5xx errors into a
  /// single grouped Sentry issue, preserving outage signal (alert on rate)
  /// without per-occurrence noise.
  static const List<String> _transientSyncFingerprint = ['transient-sync-5xx'];

  /// Downgrades transient, app-handled /sync 5xx errors.
  ///
  /// `captureFailedRequests` auto-captures every failed HTTP request as its
  /// own issue, including 502/503/504 on POST /sync that the client retries
  /// and recovers from. Such events are kept — a sustained spike of /sync 504s
  /// is a real outage signal — but demoted to [SentryLevel.warning] and grouped
  /// under one stable fingerprint so an alert can fire on rate rather than on
  /// each transient occurrence. Every other event is returned unchanged.
  ///
  /// Public to allow direct unit testing without initializing the SDK.
  static SentryEvent reclassifyTransientSyncErrors(SentryEvent event) {
    final throwable = event.throwable;
    if (throwable is! DioException) return event;

    final path = throwable.requestOptions.path;
    final statusCode = throwable.response?.statusCode;
    final isTransientSyncError =
        path.contains('/sync') &&
        statusCode != null &&
        _transientSyncStatusCodes.contains(statusCode);
    if (!isTransientSyncError) return event;

    // Mutate in place: SentryEvent.copyWith is deprecated in favour of direct
    // field assignment (matches redactSensitiveData above).
    event.level = SentryLevel.warning;
    event.fingerprint = [..._transientSyncFingerprint];
    event.tags = {...?event.tags, 'sync_transient': 'true'};
    return event;
  }

  /// Callback executed before recording each breadcrumb.
  Breadcrumb? _beforeBreadcrumb(Breadcrumb? crumb, Hint hint) {
    if (crumb == null) return null;
    return _redactBreadcrumb(crumb);
  }

  /// Removes credentials and sensitive bodies from a Sentry event in place.
  ///
  /// Public to allow direct unit testing without initializing the SDK.
  /// Returns the same event for fluent use.
  static SentryEvent redactSensitiveData(SentryEvent event) {
    final request = event.request;
    if (request != null) {
      event.request = _redactRequest(request);
    }

    final breadcrumbs = event.breadcrumbs;
    if (breadcrumbs != null) {
      for (var i = 0; i < breadcrumbs.length; i++) {
        breadcrumbs[i] = _redactBreadcrumb(breadcrumbs[i]);
      }
    }

    return event;
  }

  static SentryRequest _redactRequest(SentryRequest request) {
    final headers = _redactHeaderMap(request.headers);
    final shouldRedactBody = _isSensitiveUrl(request.url);
    final data = shouldRedactBody ? _redactedPlaceholder : request.data;

    return SentryRequest(
      url: request.url,
      method: request.method,
      queryString: request.queryString,
      cookies: request.cookies,
      fragment: request.fragment,
      apiTarget: request.apiTarget,
      data: data,
      headers: headers,
      env: request.env,
    );
  }

  static Map<String, String> _redactHeaderMap(Map<String, String> source) {
    if (source.isEmpty) return source;
    final out = Map<String, String>.from(source);
    for (final key in out.keys.toList()) {
      if (_sensitiveHeaderNames.contains(key.toLowerCase())) {
        out[key] = _redactedPlaceholder;
      }
    }
    return out;
  }

  static Breadcrumb _redactBreadcrumb(Breadcrumb crumb) {
    final data = crumb.data;
    if (data == null || data.isEmpty) return crumb;

    final sanitized = Map<String, dynamic>.from(data);
    var changed = false;

    for (final key in sanitized.keys.toList()) {
      if (_sensitiveHeaderNames.contains(key.toLowerCase())) {
        sanitized[key] = _redactedPlaceholder;
        changed = true;
      }
    }

    final url = sanitized['url'];
    if (url is String && _isSensitiveUrl(url)) {
      for (final bodyKey in _sensitiveBreadcrumbBodyKeys) {
        if (sanitized.containsKey(bodyKey)) {
          sanitized[bodyKey] = _redactedPlaceholder;
          changed = true;
        }
      }
    }

    if (!changed) return crumb;
    crumb.data = sanitized;
    return crumb;
  }

  static bool _isSensitiveUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return _sensitivePathFragments.any(lower.contains);
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
      scope.setUser(
        SentryUser(id: userId, email: email, username: username, data: extras),
      );
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
    Map<String, String>? tags,
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
      withScope: (extras != null || tags != null)
          ? (scope) {
              if (extras != null) {
                scope.setContexts('Extra Data', extras);
              }
              // Tags are indexed/searchable in Sentry (unlike "Extra Data"), so
              // promote discriminators here to allow faceting and aggregation.
              tags?.forEach(scope.setTag);
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
