import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service for handling Google User Messaging Platform (UMP) / Funding Choices
/// consent flow required for GDPR (EU), UK GDPR, and California (CCPA).
///
/// Must be invoked before [MobileAds.instance.initialize()] so that AdMob
/// receives the user's consent decision before requesting any ads.
///
/// Setup checklist:
/// - In AdMob Console (https://apps.admob.com), go to
///   Privacy & messaging → GDPR → Create message and publish, using
///   the privacy policy URL https://fishfeed.club/privacy.
/// - Repeat for the CCPA section if California users are targeted.
///
/// Without this flow Google Play submission can be rejected with
/// "App must comply with GDPR consent requirements" for EU users.
class ConsentService {
  ConsentService._();

  static final ConsentService _instance = ConsentService._();

  static ConsentService get instance => _instance;

  bool _hasRequestedConsent = false;

  /// Whether ads can be requested according to the consent state.
  ///
  /// `true` when the user is outside the EEA/UK or has provided consent.
  /// `false` when consent is required but not yet granted, or when an error
  /// prevented the SDK from determining the consent state.
  bool _canRequestAds = false;

  bool get canRequestAds => _canRequestAds;

  /// Requests consent information from Google and shows the consent form
  /// if required. Returns `true` once it is safe to call
  /// [MobileAds.instance.initialize] and to request ads.
  ///
  /// Safe to call multiple times — only the first invocation triggers the
  /// network request and the modal form.
  Future<bool> requestConsent() async {
    if (_hasRequestedConsent) {
      return _canRequestAds;
    }
    _hasRequestedConsent = true;

    final params = ConsentRequestParameters(
      // Use real consent flow in release. In debug builds the SDK still uses
      // production data unless the device is registered as a test device in
      // AdMob; see consent_debug_settings.html for details.
      consentDebugSettings: kDebugMode ? ConsentDebugSettings() : null,
    );

    final updateCompleter = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () => updateCompleter.complete(),
      (FormError error) {
        if (kDebugMode) {
          debugPrint(
            'ConsentService: requestConsentInfoUpdate failed: '
            '${error.errorCode} ${error.message}',
          );
        }
        updateCompleter.complete();
      },
    );
    await updateCompleter.future;

    final showCompleter = Completer<void>();
    unawaited(
      ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
        if (error != null && kDebugMode) {
          debugPrint(
            'ConsentService: loadAndShowConsentFormIfRequired failed: '
            '${error.errorCode} ${error.message}',
          );
        }
        showCompleter.complete();
      }),
    );
    await showCompleter.future;

    _canRequestAds = await ConsentInformation.instance.canRequestAds();

    if (kDebugMode) {
      debugPrint('ConsentService: canRequestAds = $_canRequestAds');
    }

    return _canRequestAds;
  }

  /// Whether the SDK reports that a privacy options entry point is required
  /// (typically for users in the EEA/UK/California). Apps must surface a
  /// settings menu item that calls [showPrivacyOptionsForm] when this is
  /// `true`, otherwise Google may flag the app during review.
  Future<bool> isPrivacyOptionsRequired() async {
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Reopens the consent form so the user can change their previous choice.
  /// Wire this to a "Manage privacy choices" item in the app settings.
  Future<void> showPrivacyOptionsForm() async {
    final completer = Completer<void>();
    unawaited(
      ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (error != null && kDebugMode) {
          debugPrint(
            'ConsentService: showPrivacyOptionsForm failed: '
            '${error.errorCode} ${error.message}',
          );
        }
        completer.complete();
      }),
    );
    await completer.future;

    _canRequestAds = await ConsentInformation.instance.canRequestAds();
  }

  /// Resets the local consent state. Intended for QA only.
  @visibleForTesting
  Future<void> reset() async {
    await ConsentInformation.instance.reset();
    _hasRequestedConsent = false;
    _canRequestAds = false;
  }
}
