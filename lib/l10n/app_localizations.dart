import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'FishFeed'**
  String get appTitle;

  /// Welcome message shown on the home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to FishFeed'**
  String get welcomeMessage;

  /// Text for the login button
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginButton;

  /// Text for the register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Calendar screen title
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Home screen title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Generic loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Light mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// System theme mode label
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// Validation error for required fields
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// Validation error for invalid email
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// Validation error for weak password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters with 1 number and 1 uppercase letter'**
  String get invalidPasswordFormat;

  /// Text before register link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Divider text between form and OAuth buttons
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Validation error when passwords don't match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Text for the create account button
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountButton;

  /// Text before login link on register screen
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Text before Terms of Service link
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTermsPrefix;

  /// Terms of Service link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Validation error when ToS checkbox is not checked
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms of Service'**
  String get tosCheckboxRequired;

  /// Password strength indicator - weak
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordWeak;

  /// Password strength indicator - medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get passwordMedium;

  /// Password strength indicator - strong
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrong;

  /// Register screen title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Error message for network failures
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNoConnection;

  /// Error message for server failures
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// Error message for authentication failures
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get errorInvalidCredentials;

  /// Error message when registration email is already taken
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get errorEmailAlreadyExists;

  /// Error message when refresh token is invalid or expired
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// Error message for invalid password reset token
  ///
  /// In en, this message translates to:
  /// **'This password reset link is invalid or has expired.'**
  String get errorInvalidResetLink;

  /// Error message for wrong old password during change
  ///
  /// In en, this message translates to:
  /// **'Your current password is incorrect.'**
  String get errorInvalidOldPassword;

  /// Error message when OAuth user tries to change password
  ///
  /// In en, this message translates to:
  /// **'Password change isn\'t available for accounts created with Google or Apple.'**
  String get errorOAuthAccountPasswordChange;

  /// Error message when OAuth provider is not configured on backend
  ///
  /// In en, this message translates to:
  /// **'This sign-in option is currently unavailable. Please try another method.'**
  String get errorOAuthProviderUnavailable;

  /// Error message for rate limiting
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorTooManyRequests;

  /// Error message for validation failures
  ///
  /// In en, this message translates to:
  /// **'Please check your input and try again.'**
  String get errorValidation;

  /// Error message for OAuth failures
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get errorOAuth;

  /// Error message for Google OAuth failures
  ///
  /// In en, this message translates to:
  /// **'Google sign in failed. Please try again.'**
  String get errorGoogleSignIn;

  /// Error message for Apple OAuth failures
  ///
  /// In en, this message translates to:
  /// **'Apple sign in failed. Please try again.'**
  String get errorAppleSignIn;

  /// Error message when user cancels an operation
  ///
  /// In en, this message translates to:
  /// **'Operation was cancelled.'**
  String get errorOperationCancelled;

  /// Error message for cache/storage failures
  ///
  /// In en, this message translates to:
  /// **'Local storage error. Please restart the app.'**
  String get errorLocalStorage;

  /// Error message for unexpected failures
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorUnexpected;

  /// Success message after login
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get successLogin;

  /// Success message after registration
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get successRegister;

  /// Success message after logout
  ///
  /// In en, this message translates to:
  /// **'You have been logged out.'**
  String get successLogout;

  /// Title for notification permission dialog
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notificationPermissionTitle;

  /// Description explaining why notifications are needed
  ///
  /// In en, this message translates to:
  /// **'Get timely reminders to feed your fish. We\'ll notify you at scheduled feeding times so you never miss a meal.'**
  String get notificationPermissionDescription;

  /// Button to enable notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notificationPermissionEnable;

  /// Button to decline notifications for now
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get notificationPermissionLater;

  /// Title for the notifications disabled banner
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsBannerTitle;

  /// Description for the notifications disabled banner
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive feeding reminders'**
  String get notificationsBannerDescription;

  /// Action button on notifications banner
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get notificationsBannerAction;

  /// Notifications section title in settings
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSettingsTitle;

  /// Button to open system settings for notifications
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get notificationsSettingsOpenSettings;

  /// Hint text when notifications are disabled
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Tap to open settings and enable them.'**
  String get notificationsSettingsDisabledHint;

  /// Title for the freeze day dialog
  ///
  /// In en, this message translates to:
  /// **'Missed Feeding'**
  String get freezeDayDialogTitle;

  /// Description in the freeze day dialog when freeze is available
  ///
  /// In en, this message translates to:
  /// **'You missed feeding your fish today. Use a freeze day to protect your streak!'**
  String get freezeDayDialogDescription;

  /// Description in the freeze day dialog when no freeze is available
  ///
  /// In en, this message translates to:
  /// **'You missed feeding your fish today and have no freeze days left. Your streak will be reset.'**
  String get freezeDayDialogNoFreezeDescription;

  /// Shows the streak count at risk
  ///
  /// In en, this message translates to:
  /// **'{count} day streak at risk'**
  String freezeDayDialogStreakAtRisk(int count);

  /// Button to use a freeze day
  ///
  /// In en, this message translates to:
  /// **'Use Freeze Day ({count} left)'**
  String freezeDayDialogUseFreeze(int count);

  /// Button to accept losing the streak
  ///
  /// In en, this message translates to:
  /// **'Lose Streak'**
  String get freezeDayDialogLoseStreak;

  /// Tooltip when no freeze days available
  ///
  /// In en, this message translates to:
  /// **'No freeze days left this month'**
  String get freezeIndicatorTooltipNone;

  /// Tooltip when 1 freeze day available
  ///
  /// In en, this message translates to:
  /// **'1 freeze day available'**
  String get freezeIndicatorTooltipOne;

  /// Tooltip when multiple freeze days available
  ///
  /// In en, this message translates to:
  /// **'{count} freeze days available'**
  String freezeIndicatorTooltipMany(int count);

  /// Title for freeze warning notification
  ///
  /// In en, this message translates to:
  /// **'Streak at Risk!'**
  String get freezeWarningNotificationTitle;

  /// Body for freeze warning notification
  ///
  /// In en, this message translates to:
  /// **'You have {freezeCount} freeze day(s) available to protect your {streakCount} day streak!'**
  String freezeWarningNotificationBody(int freezeCount, int streakCount);

  /// Title for empty state on today view
  ///
  /// In en, this message translates to:
  /// **'No events today'**
  String get emptyStateTodayTitle;

  /// Description for empty state on today view
  ///
  /// In en, this message translates to:
  /// **'All your fish are fed! Enjoy the day.'**
  String get emptyStateTodayDescription;

  /// Title for empty state on fish list
  ///
  /// In en, this message translates to:
  /// **'No fish yet'**
  String get emptyStateFishListTitle;

  /// Description for empty state on fish list
  ///
  /// In en, this message translates to:
  /// **'Add your first fish to start tracking feeding schedules.'**
  String get emptyStateFishListDescription;

  /// Action button for empty state on fish list
  ///
  /// In en, this message translates to:
  /// **'Add Fish'**
  String get emptyStateFishListAction;

  /// Title for empty state on achievements screen
  ///
  /// In en, this message translates to:
  /// **'No achievements yet'**
  String get emptyStateAchievementsTitle;

  /// Description for empty state on achievements screen
  ///
  /// In en, this message translates to:
  /// **'Start feeding your fish regularly to unlock achievements!'**
  String get emptyStateAchievementsDescription;

  /// Title for empty state on calendar screen
  ///
  /// In en, this message translates to:
  /// **'No feeding history'**
  String get emptyStateCalendarTitle;

  /// Description for empty state on calendar screen
  ///
  /// In en, this message translates to:
  /// **'Start tracking feedings to see your history here.'**
  String get emptyStateCalendarDescription;

  /// Title for network error state
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get errorStateNetworkTitle;

  /// Description for network error state
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get errorStateNetworkDescription;

  /// Title for server error state
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorStateServerTitle;

  /// Description for server error state
  ///
  /// In en, this message translates to:
  /// **'We\'re having trouble connecting. Please try again later.'**
  String get errorStateServerDescription;

  /// Title for timeout error state
  ///
  /// In en, this message translates to:
  /// **'Server not responding'**
  String get errorStateTimeoutTitle;

  /// Description for timeout error state
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Please try again.'**
  String get errorStateTimeoutDescription;

  /// Title for generic error state
  ///
  /// In en, this message translates to:
  /// **'Oops!'**
  String get errorStateGenericTitle;

  /// Description for generic error state
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorStateGenericDescription;

  /// Try again button text for error states
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get errorStateTryAgain;

  /// Contact support link text for error states
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get errorStateContactSupport;

  /// Title for the offline banner
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineBannerTitle;

  /// Description for the offline banner
  ///
  /// In en, this message translates to:
  /// **'Some features may not be available'**
  String get offlineBannerDescription;

  /// Title for low storage warning dialog
  ///
  /// In en, this message translates to:
  /// **'Storage Low'**
  String get lowStorageTitle;

  /// Description for low storage warning
  ///
  /// In en, this message translates to:
  /// **'Your device has less than {size} MB of free storage. Some features may not work properly.'**
  String lowStorageDescription(int size);

  /// Button to clear cache
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get lowStorageClearCache;

  /// Button to dismiss low storage warning
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get lowStorageDismiss;

  /// Success message when cache is cleared
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheCleared;

  /// Pluralized fish count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No fish} =1{1 fish} other{{count} fish}}'**
  String fishCount(int count);

  /// Pluralized day count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// Pluralized achievement count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No achievements} =1{1 achievement} other{{count} achievements}}'**
  String achievementCount(int count);

  /// Pluralized streak days
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 day streak} =1{1 day streak} other{{count} day streak}}'**
  String streakDays(int count);

  /// Sync status when device is offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncStatusOffline;

  /// Sync status when sync is in progress
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncStatusSyncing;

  /// Sync status when sync is complete
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// Sync status when sync has failed
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncStatusError;

  /// Relative time for less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get syncStatusJustNow;

  /// Relative time for minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String syncStatusMinutesAgo(int count);

  /// Relative time for hours ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String syncStatusHoursAgo(int count);

  /// Relative time for days ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String syncStatusDaysAgo(int count);

  /// Message when trying to sync while offline
  ///
  /// In en, this message translates to:
  /// **'Cannot sync while offline'**
  String get syncCannotSyncOffline;

  /// Title for the conflict resolution dialog
  ///
  /// In en, this message translates to:
  /// **'Sync Conflict'**
  String get conflictDialogTitle;

  /// Description for the conflict resolution dialog
  ///
  /// In en, this message translates to:
  /// **'This item was modified on another device. Choose which version to keep.'**
  String get conflictDialogDescription;

  /// Label for the list of conflicting fields
  ///
  /// In en, this message translates to:
  /// **'Changed fields:'**
  String get conflictDifferingFields;

  /// Label for the local version in conflict dialog
  ///
  /// In en, this message translates to:
  /// **'Your version'**
  String get conflictLocalVersion;

  /// Label for the server version in conflict dialog
  ///
  /// In en, this message translates to:
  /// **'Server version'**
  String get conflictServerVersion;

  /// Button to keep local version
  ///
  /// In en, this message translates to:
  /// **'Keep mine'**
  String get conflictKeepMyVersion;

  /// Button to use server version
  ///
  /// In en, this message translates to:
  /// **'Use server'**
  String get conflictUseServerVersion;

  /// Title for deletion conflict dialog
  ///
  /// In en, this message translates to:
  /// **'Deletion Conflict'**
  String get conflictDeletionTitle;

  /// Description for deletion conflict dialog
  ///
  /// In en, this message translates to:
  /// **'This item was deleted on another device but you made changes locally. Choose whether to restore or delete it.'**
  String get conflictDeletionDescription;

  /// Button to restore deleted item
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get conflictRestoreItem;

  /// Button to confirm deletion
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get conflictDeleteItem;

  /// Shows when item was deleted on server
  ///
  /// In en, this message translates to:
  /// **'Deleted on {date}'**
  String conflictDeletedOn(String date);

  /// My Aquarium section title
  ///
  /// In en, this message translates to:
  /// **'My Aquarium'**
  String get myAquarium;

  /// Button to manage fish in aquarium
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageFish;

  /// Button to add a new fish
  ///
  /// In en, this message translates to:
  /// **'Add Fish'**
  String get addFish;

  /// Edit fish screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Fish'**
  String get editFish;

  /// Delete fish action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteFish;

  /// Delete fish confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteFishTitle(String name);

  /// Delete fish confirmation message
  ///
  /// In en, this message translates to:
  /// **'This will remove the fish and its feeding schedule.'**
  String get confirmDeleteFish;

  /// Fish quantity label
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fishQuantity;

  /// Custom name field label
  ///
  /// In en, this message translates to:
  /// **'Custom Name'**
  String get customName;

  /// Custom name field hint
  ///
  /// In en, this message translates to:
  /// **'Give your fish a name'**
  String get customNameHint;

  /// Custom name field helper text
  ///
  /// In en, this message translates to:
  /// **'Optional - leave blank to use species name'**
  String get customNameOptional;

  /// Empty aquarium state title
  ///
  /// In en, this message translates to:
  /// **'No fish yet'**
  String get emptyAquarium;

  /// Empty state call to action
  ///
  /// In en, this message translates to:
  /// **'Add your first fish'**
  String get addFirstFish;

  /// Empty state description on aquarium screen
  ///
  /// In en, this message translates to:
  /// **'Add your first fish to start tracking feedings'**
  String get addFirstFishDescription;

  /// Success message when fish is added
  ///
  /// In en, this message translates to:
  /// **'{name} added successfully'**
  String fishAddedSuccessfully(String name);

  /// Success message when fish is deleted
  ///
  /// In en, this message translates to:
  /// **'Fish deleted'**
  String get fishDeletedSuccessfully;

  /// Success message when fish is updated
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get fishUpdatedSuccessfully;

  /// Shows remaining count in preview
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreCount(int count);

  /// Tooltip for add fish FAB
  ///
  /// In en, this message translates to:
  /// **'Add fish'**
  String get addFishTooltip;

  /// Subtitle on edit fish screen
  ///
  /// In en, this message translates to:
  /// **'Edit fish details'**
  String get editFishDetails;

  /// Error title when fish not found
  ///
  /// In en, this message translates to:
  /// **'Fish not found'**
  String get fishNotFound;

  /// Error description when fish not found
  ///
  /// In en, this message translates to:
  /// **'The fish you are trying to edit no longer exists.'**
  String get fishNotFoundDescription;

  /// Button to go back
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// Error message when save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes. Please try again.'**
  String get failedToSaveChanges;

  /// Option to add fish using AI camera
  ///
  /// In en, this message translates to:
  /// **'Scan with AI Camera'**
  String get scanWithAiCamera;

  /// Subtitle for AI camera option
  ///
  /// In en, this message translates to:
  /// **'Take a photo to identify fish species'**
  String get takePhotoToIdentify;

  /// Option to manually select fish from list
  ///
  /// In en, this message translates to:
  /// **'Select from list'**
  String get selectFromList;

  /// Subtitle for manual selection option
  ///
  /// In en, this message translates to:
  /// **'Choose from available species'**
  String get chooseFromSpeciesList;

  /// Statistics section title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// Label for feedings count
  ///
  /// In en, this message translates to:
  /// **'Feedings'**
  String get feedingsLabel;

  /// Label for days using the app
  ///
  /// In en, this message translates to:
  /// **'Days with FishFeed'**
  String get daysWithApp;

  /// Label for on-time feeding percentage
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get onTimeLabel;

  /// Label for user level
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// Label for XP/experience
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceLabel;

  /// Streak section title
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakTitle;

  /// Label for current streak
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreakLabel;

  /// Label for best streak
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get bestStreakLabel;

  /// Label for freeze days
  ///
  /// In en, this message translates to:
  /// **'Freeze'**
  String get freezeLabel;

  /// Title for freeze days dialog
  ///
  /// In en, this message translates to:
  /// **'Freeze Days'**
  String get freezeDaysTitle;

  /// Description of freeze days
  ///
  /// In en, this message translates to:
  /// **'Freeze days protect your streak when you miss a feeding.'**
  String get freezeDaysDescription;

  /// Info about monthly freeze days
  ///
  /// In en, this message translates to:
  /// **'You get {count} freeze days per month'**
  String freezeDaysPerMonth(int count);

  /// Info about automatic freeze usage
  ///
  /// In en, this message translates to:
  /// **'Freeze is used automatically when you miss a day'**
  String get freezeDaysAutoUsed;

  /// Shows available freeze days
  ///
  /// In en, this message translates to:
  /// **'Available freeze days: {count}'**
  String freezeDaysAvailable(int count);

  /// Button text to watch rewarded ad to earn a freeze day
  ///
  /// In en, this message translates to:
  /// **'Watch Ad for +1 Freeze Day'**
  String get watchAdForFreezeDay;

  /// Snackbar message after earning a freeze day from a rewarded ad
  ///
  /// In en, this message translates to:
  /// **'You earned +1 freeze day!'**
  String get freezeDayEarned;

  /// Got it button text
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotItButton;

  /// Milestone badge text
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String milestoneDays(int count);

  /// Streak tooltip text
  ///
  /// In en, this message translates to:
  /// **'{count} days in a row!'**
  String streakDaysInRow(int count);

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Achievements screen/section title
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// Error message when achievements fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load achievements'**
  String get achievementFailedToLoad;

  /// Hint for locked achievements
  ///
  /// In en, this message translates to:
  /// **'Complete the challenge to unlock'**
  String get achievementCompleteToUnlock;

  /// Label for progress indicator
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// Share button text while sharing
  ///
  /// In en, this message translates to:
  /// **'Sharing...'**
  String get sharingButton;

  /// Achievement unlock overlay title
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get achievementUnlocked;

  /// Hint to close overlay
  ///
  /// In en, this message translates to:
  /// **'Tap to close'**
  String get tapToClose;

  /// Achievement progress text
  ///
  /// In en, this message translates to:
  /// **'Progress: {percent}%'**
  String achievementProgress(int percent);

  /// Text for locked achievements
  ///
  /// In en, this message translates to:
  /// **'Not unlocked yet'**
  String get notUnlockedYet;

  /// Locked status label
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// Title for achievement progress section
  ///
  /// In en, this message translates to:
  /// **'Achievement Progress'**
  String get achievementProgressTitle;

  /// Text showing when achievement was unlocked
  ///
  /// In en, this message translates to:
  /// **'Unlocked {date}'**
  String unlockedOn(String date);

  /// Feeding card label
  ///
  /// In en, this message translates to:
  /// **'Feeding'**
  String get feedingLabel;

  /// Snackbar message when feeding is completed
  ///
  /// In en, this message translates to:
  /// **'Feeding completed!'**
  String get feedingCompleted;

  /// Missed feeding status label
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get feedingMissed;

  /// Status message for completed feeding
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get statusGreatJob;

  /// Status message for missed feeding
  ///
  /// In en, this message translates to:
  /// **'Next time will work!'**
  String get statusNextTime;

  /// Status message for pending feeding
  ///
  /// In en, this message translates to:
  /// **'Pending feeding'**
  String get statusPendingFeeding;

  /// Beginner level name
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// Caretaker level name
  ///
  /// In en, this message translates to:
  /// **'Caretaker'**
  String get levelCaretaker;

  /// Master level name
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get levelMaster;

  /// Pro level name
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get levelPro;

  /// Tooltip for beginner level
  ///
  /// In en, this message translates to:
  /// **'Beginner Aquarist - first steps in fish care'**
  String get levelBeginnerTooltip;

  /// Tooltip for caretaker level
  ///
  /// In en, this message translates to:
  /// **'Caretaker - consistently caring for your fish'**
  String get levelCaretakerTooltip;

  /// Tooltip for master level
  ///
  /// In en, this message translates to:
  /// **'Master - experienced aquarist'**
  String get levelMasterTooltip;

  /// Tooltip for pro level
  ///
  /// In en, this message translates to:
  /// **'Professional - expert in fish care!'**
  String get levelProTooltip;

  /// Text shown when user is at max level
  ///
  /// In en, this message translates to:
  /// **'Max Level'**
  String get maxLevel;

  /// Family access screen title
  ///
  /// In en, this message translates to:
  /// **'Family Access'**
  String get familyAccess;

  /// Family mode section title
  ///
  /// In en, this message translates to:
  /// **'Family Mode'**
  String get familyMode;

  /// Description of family mode
  ///
  /// In en, this message translates to:
  /// **'Invite family members to care for your fish together. Everyone can feed and see who fed.'**
  String get familyModeDescription;

  /// Section title for active invitations
  ///
  /// In en, this message translates to:
  /// **'Active Invitations'**
  String get activeInvitations;

  /// Section title for family members
  ///
  /// In en, this message translates to:
  /// **'Family Members'**
  String get familyMembers;

  /// Shows current and max member count
  ///
  /// In en, this message translates to:
  /// **'Members: {current} / {max}'**
  String membersCount(int current, int max);

  /// Text when member limit is reached
  ///
  /// In en, this message translates to:
  /// **'Limit reached'**
  String get limitReached;

  /// Text when free plan limit is reached
  ///
  /// In en, this message translates to:
  /// **'Free plan limit reached'**
  String get freePlanLimitReached;

  /// Premium upgrade prompt for family
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium to add up to {count} family members and access feeding statistics.'**
  String upgradeToPremiumFamily(int count);

  /// Premium benefit - members count
  ///
  /// In en, this message translates to:
  /// **'Up to {count} members'**
  String upToMembers(int count);

  /// Premium feature name
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsFeature;

  /// Premium feature name
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get managementFeature;

  /// Button to go to premium
  ///
  /// In en, this message translates to:
  /// **'Go to Premium'**
  String get goToPremium;

  /// Button to invite family member
  ///
  /// In en, this message translates to:
  /// **'Invite family member'**
  String get inviteFamilyMember;

  /// Text when user is the only member
  ///
  /// In en, this message translates to:
  /// **'You are the only family member'**
  String get youAreOnlyMember;

  /// Prompt to invite someone
  ///
  /// In en, this message translates to:
  /// **'Invite someone to care for the aquarium together'**
  String get inviteSomeone;

  /// Share text for family invitation
  ///
  /// In en, this message translates to:
  /// **'Join my aquarium in FishFeed!\n\nFollow the link: {link}\n\nOr enter code: {code}'**
  String joinMyAquarium(String link, String code);

  /// Subject for invitation share
  ///
  /// In en, this message translates to:
  /// **'Invitation to FishFeed'**
  String get invitationToFishFeed;

  /// Snackbar when link is copied
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// Cancel invitation dialog title
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation?'**
  String get cancelInvitation;

  /// Cancel invitation dialog description
  ///
  /// In en, this message translates to:
  /// **'This invitation can no longer be used.'**
  String get cancelInvitationDescription;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Remove member dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get removeMember;

  /// Remove member dialog description
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name}?'**
  String removeMemberDescription(String name);

  /// Remove button text
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Leave family dialog title
  ///
  /// In en, this message translates to:
  /// **'Leave family?'**
  String get leaveFamily;

  /// Leave family dialog description
  ///
  /// In en, this message translates to:
  /// **'You will lose access to this shared aquarium.'**
  String get leaveFamilyDescription;

  /// Leave button text
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// Title when invitation is created
  ///
  /// In en, this message translates to:
  /// **'Invitation created!'**
  String get invitationCreated;

  /// Shows invitation validity
  ///
  /// In en, this message translates to:
  /// **'Valid for {hours} hours'**
  String validForHours(int hours);

  /// Label for invitation code
  ///
  /// In en, this message translates to:
  /// **'Invitation code'**
  String get invitationCode;

  /// Copy button text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Short validity text for hours
  ///
  /// In en, this message translates to:
  /// **'Valid for {hours}h'**
  String validForHoursShort(int hours);

  /// Short validity text for minutes
  ///
  /// In en, this message translates to:
  /// **'Valid for {minutes}m'**
  String validForMinutesShort(int minutes);

  /// Text when invitation is about to expire
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get expiring;

  /// Default user name
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Owner role label
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// Member role label
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// Shows when member joined
  ///
  /// In en, this message translates to:
  /// **'Joined: {date}'**
  String joinedDate(String date);

  /// Feedings count this week
  ///
  /// In en, this message translates to:
  /// **'{count} this week'**
  String feedingsThisWeek(int count);

  /// Feedings count this month
  ///
  /// In en, this message translates to:
  /// **'{count} this month'**
  String feedingsThisMonth(int count);

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// Loading text when joining family
  ///
  /// In en, this message translates to:
  /// **'Joining family...'**
  String get joiningFamily;

  /// Processing invitation message
  ///
  /// In en, this message translates to:
  /// **'Please wait while we process your invitation'**
  String get processingInvitation;

  /// Success title
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// Success message after joining family
  ///
  /// In en, this message translates to:
  /// **'You have successfully joined the family aquarium'**
  String get joinedFamilySuccess;

  /// Redirecting message
  ///
  /// In en, this message translates to:
  /// **'Redirecting...'**
  String get redirecting;

  /// Title when login is required
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequired;

  /// Title for invitation error
  ///
  /// In en, this message translates to:
  /// **'Invitation error'**
  String get invitationError;

  /// Message prompting login for invitation
  ///
  /// In en, this message translates to:
  /// **'Log in to accept the invitation'**
  String get loginToAcceptInvitation;

  /// Log in button text
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// Go to home button text
  ///
  /// In en, this message translates to:
  /// **'To home'**
  String get toHome;

  /// Toast message when family member completes feeding
  ///
  /// In en, this message translates to:
  /// **'Feeding completed: {userName}'**
  String feedingCompletedByUser(String userName);

  /// Default name for family member
  ///
  /// In en, this message translates to:
  /// **'Family member'**
  String get familyMember;

  /// Feeding done message
  ///
  /// In en, this message translates to:
  /// **'Feeding done'**
  String get feedingDone;

  /// Notification title for feeding time
  ///
  /// In en, this message translates to:
  /// **'Feeding Time!'**
  String get feedingTime;

  /// Notification body for feeding time
  ///
  /// In en, this message translates to:
  /// **'Time to feed {fishName}'**
  String timeToFeed(String fishName);

  /// Generic fish name
  ///
  /// In en, this message translates to:
  /// **'your fish'**
  String get yourFish;

  /// Notification title for overdue event
  ///
  /// In en, this message translates to:
  /// **'Event overdue'**
  String get eventOverdue;

  /// Notification body for overdue event
  ///
  /// In en, this message translates to:
  /// **'Event overdue for {fishName}'**
  String eventOverdueFor(String fishName);

  /// Notification title for status confirmation
  ///
  /// In en, this message translates to:
  /// **'Confirm status'**
  String get confirmStatus;

  /// Notification body for status confirmation
  ///
  /// In en, this message translates to:
  /// **'Confirm feeding status'**
  String get confirmFeedingStatus;

  /// Notification action for marking as fed
  ///
  /// In en, this message translates to:
  /// **'Fed ✓'**
  String get fedAction;

  /// Notification action for snoozing
  ///
  /// In en, this message translates to:
  /// **'Snooze 15m'**
  String get snoozeAction;

  /// Generic share text for achievement
  ///
  /// In en, this message translates to:
  /// **'I got the achievement \"{title}\" in FishFeed! 🐟🏆'**
  String shareAchievementGeneric(String title);

  /// Share text for first feeding achievement
  ///
  /// In en, this message translates to:
  /// **'I started caring for fish in FishFeed! 🐟 First feeding done! 🎉'**
  String get shareFirstFeeding;

  /// Share text for 7-day streak
  ///
  /// In en, this message translates to:
  /// **'A week without misses! 🔥 My streak in FishFeed: 7 days! 🏆'**
  String get shareStreak7;

  /// Share text for 30-day streak
  ///
  /// In en, this message translates to:
  /// **'A month of perfection! 🌟 30 days of feedings in a row in FishFeed! 🔥'**
  String get shareStreak30;

  /// Share text for 100-day streak
  ///
  /// In en, this message translates to:
  /// **'Legendary streak! 💎 100 days of feedings without misses in FishFeed! 🏆🔥'**
  String get shareStreak100;

  /// Share text for perfect week achievement
  ///
  /// In en, this message translates to:
  /// **'Perfect week! ✨ No missed feedings in FishFeed! 🐟'**
  String get sharePerfectWeek;

  /// Share text for 50 feedings achievement
  ///
  /// In en, this message translates to:
  /// **'Dedicated caretaker! 🐠 50 feedings completed in FishFeed! 🎉'**
  String get shareFeedings50;

  /// Share text for 100 feedings achievement
  ///
  /// In en, this message translates to:
  /// **'A hundred feedings! 🎯 Fed my fish 100 times in FishFeed! 🐟'**
  String get shareFeedings100;

  /// Share text for 500 feedings achievement
  ///
  /// In en, this message translates to:
  /// **'Feeding master! 👑 500 feedings in FishFeed! My fish are in good hands! 🐟🏆'**
  String get shareFeedings500;

  /// Share text for 1000 feedings achievement
  ///
  /// In en, this message translates to:
  /// **'Fish whisperer! 🌊 1000 feedings in FishFeed! True dedication! 🐟💎'**
  String get shareFeedings1000;

  /// Share text for 365-day streak achievement
  ///
  /// In en, this message translates to:
  /// **'A full year! 🏅 365 days of feedings without misses in FishFeed! 🐟💎🔥'**
  String get shareStreak365;

  /// Share text for early bird achievement
  ///
  /// In en, this message translates to:
  /// **'Early Bird! 🌅 Fed my fish before sunrise in FishFeed! 🐟'**
  String get shareEarlyBird;

  /// Share text for night owl achievement
  ///
  /// In en, this message translates to:
  /// **'Night Owl! 🌙 Late-night feeding in FishFeed! 🐟'**
  String get shareNightOwl;

  /// Share text for first fish achievement
  ///
  /// In en, this message translates to:
  /// **'My first fish! 🐟 Added my first fish to FishFeed! 🎉'**
  String get shareFirstFish;

  /// Share text for 10 fish collector achievement
  ///
  /// In en, this message translates to:
  /// **'Fish Collector! 🐠 10 fish in my FishFeed aquariums! 🏆'**
  String get shareFishCollector10;

  /// Share text for 50 fish collector achievement
  ///
  /// In en, this message translates to:
  /// **'Master Collector! 🐟 50 fish in FishFeed! A true aquarist! 🏆💎'**
  String get shareFishCollector50;

  /// Share text for 5 species explorer achievement
  ///
  /// In en, this message translates to:
  /// **'Species Explorer! 🔍 5 different species in FishFeed! 🐟'**
  String get shareSpeciesExplorer5;

  /// Share text for 10 species explorer achievement
  ///
  /// In en, this message translates to:
  /// **'Species Expert! 🧬 10 different species in FishFeed! 🐠🏆'**
  String get shareSpeciesExplorer10;

  /// Share text for 20 species explorer achievement
  ///
  /// In en, this message translates to:
  /// **'Species Master! 🌊 20 different species in FishFeed! True biodiversity! 🐟💎'**
  String get shareSpeciesExplorer20;

  /// Share text for first aquarium achievement
  ///
  /// In en, this message translates to:
  /// **'My first aquarium! 🏠 Set up my first aquarium in FishFeed! 🐟'**
  String get shareFirstAquarium;

  /// Share text for 3 aquariums collector achievement
  ///
  /// In en, this message translates to:
  /// **'Aquarium Enthusiast! 🏠 3 aquariums in FishFeed! 🐟🏆'**
  String get shareAquariumCollector3;

  /// Share text for 10 aquariums collector achievement
  ///
  /// In en, this message translates to:
  /// **'Aquarium Empire! 🏰 10 aquariums in FishFeed! A true master! 🐟💎'**
  String get shareAquariumCollector10;

  /// Share text for first family member achievement
  ///
  /// In en, this message translates to:
  /// **'Teamwork! 👨‍👩‍👧 Invited my first family member to FishFeed! 🐟'**
  String get shareFamilyFirst;

  /// Share text for 3 family members achievement
  ///
  /// In en, this message translates to:
  /// **'Family Team! 👨‍👩‍👧‍👦 3 family members caring for fish in FishFeed! 🐟🏆'**
  String get shareFamilyTeam3;

  /// Share text for first share achievement
  ///
  /// In en, this message translates to:
  /// **'Shared my first achievement in FishFeed! 📢 Join me! 🐟'**
  String get shareFirstShare;

  /// Share text for long streak (50+)
  ///
  /// In en, this message translates to:
  /// **'Incredible! 💎 My streak in {appName}: {days} days! 🔥🏆'**
  String shareStreakLong(String appName, int days);

  /// Share text for medium streak (20+)
  ///
  /// In en, this message translates to:
  /// **'Amazing! 🌟 My streak in {appName}: {days} days! 🔥'**
  String shareStreakMedium(String appName, int days);

  /// Share text for short streak (7+)
  ///
  /// In en, this message translates to:
  /// **'Awesome! 🔥 My streak in {appName}: {days} days!'**
  String shareStreakShort(String appName, int days);

  /// Default share text for streak
  ///
  /// In en, this message translates to:
  /// **'My streak in {appName}: {days} days! 🐟'**
  String shareStreakDefault(String appName, int days);

  /// Text on share card for achievement
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENT UNLOCKED'**
  String get achievementUnlockedCard;

  /// Today date label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Yesterday date label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Tomorrow date label
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Monday weekday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Tuesday weekday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Wednesday weekday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Thursday weekday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Friday weekday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Saturday weekday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Sunday weekday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// January abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// February abbreviation
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// March abbreviation
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// April abbreviation
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// May abbreviation
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// June abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// July abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// August abbreviation
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// September abbreviation
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// October abbreviation
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// November abbreviation
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// December abbreviation
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// Text when no feedings for a day
  ///
  /// In en, this message translates to:
  /// **'No feedings scheduled'**
  String get noFeedingsScheduled;

  /// Text showing feedings progress
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} feedings completed'**
  String feedingsCompleted(int completed, int total);

  /// Complete status label
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get statusComplete;

  /// Missed status label
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get statusMissed;

  /// Partial status label
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statusPartial;

  /// No data status label
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get statusNoData;

  /// Loading message for feedings
  ///
  /// In en, this message translates to:
  /// **'Loading feedings...'**
  String get loadingFeedings;

  /// Tooltip for all fed status
  ///
  /// In en, this message translates to:
  /// **'All feedings completed'**
  String get allFeedingsCompleted;

  /// Tooltip for all missed status
  ///
  /// In en, this message translates to:
  /// **'All feedings missed'**
  String get allFeedingsMissed;

  /// Tooltip for partial status
  ///
  /// In en, this message translates to:
  /// **'Some feedings completed'**
  String get someFeedingsCompleted;

  /// Tooltip for no data status
  ///
  /// In en, this message translates to:
  /// **'No feeding data'**
  String get noFeedingData;

  /// Logout confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutConfirmTitle;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// Delete account dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// Final delete account confirmation title
  ///
  /// In en, this message translates to:
  /// **'Final Confirmation'**
  String get deleteAccountConfirm;

  /// Delete account button text
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteMyAccount;

  /// Subscription section label
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// Restore purchases button
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// Restore purchases subtitle
  ///
  /// In en, this message translates to:
  /// **'Recover previous purchases'**
  String get recoverPreviousPurchases;

  /// Take photo option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Choose from gallery option
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Nickname field label
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// Success message for nickname update
  ///
  /// In en, this message translates to:
  /// **'Nickname updated successfully'**
  String get nicknameUpdated;

  /// Profile share failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to share profile'**
  String get failedToShareProfile;

  /// Share profile button
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfile;

  /// Premium feature label
  ///
  /// In en, this message translates to:
  /// **'Premium feature'**
  String get premiumFeature;

  /// Upgrade button text
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// Upgrade to premium button
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// Premium benefit description
  ///
  /// In en, this message translates to:
  /// **'Unlock all features'**
  String get unlockAllFeatures;

  /// Upgrade prompt with feature name
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock {feature}'**
  String upgradeToUnlock(String feature);

  /// No ads premium benefit
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get noAds;

  /// Unlimited AI scans premium benefit
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Scans'**
  String get unlimitedAiScans;

  /// 6 months history premium benefit
  ///
  /// In en, this message translates to:
  /// **'6 Months History'**
  String get sixMonthsHistory;

  /// View plans button
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlans;

  /// Trial badge label
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trial;

  /// Premium badge label
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// Free badge label
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// Go premium button
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// Add manually button
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addManually;

  /// Maybe later button
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// Remove ads button
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAds;

  /// One-time purchase label
  ///
  /// In en, this message translates to:
  /// **'One-time purchase'**
  String get oneTimePurchase;

  /// Trial banner description
  ///
  /// In en, this message translates to:
  /// **'Try all premium features. Cancel anytime.'**
  String get tryPremiumFeatures;

  /// AI scan paywall description
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium for unlimited AI fish recognition'**
  String get upgradePremiumAiScans;

  /// Premium benefit
  ///
  /// In en, this message translates to:
  /// **'Priority processing'**
  String get priorityProcessing;

  /// Premium benefit
  ///
  /// In en, this message translates to:
  /// **'Higher accuracy'**
  String get higherAccuracy;

  /// AI camera analyzing text
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// Retake photo button
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// Button label for manual species selection
  ///
  /// In en, this message translates to:
  /// **'Select Manually'**
  String get selectManually;

  /// Button label to confirm despite low confidence
  ///
  /// In en, this message translates to:
  /// **'Confirm Anyway'**
  String get confirmAnyway;

  /// Button label to indicate incorrect detection
  ///
  /// In en, this message translates to:
  /// **'Not correct?'**
  String get notCorrect;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Text when no AI scans remaining
  ///
  /// In en, this message translates to:
  /// **'No scans left'**
  String get noScansLeft;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Food type label
  ///
  /// In en, this message translates to:
  /// **'Food type'**
  String get foodType;

  /// Portion label
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get portion;

  /// From time label
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// To time label
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// Google sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Apple sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// Appearance screen title
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Premium purchase success message
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium!'**
  String get welcomeToPremium;

  /// Ads removal success message
  ///
  /// In en, this message translates to:
  /// **'Ads removed successfully!'**
  String get adsRemovedSuccessfully;

  /// No purchases to restore message
  ///
  /// In en, this message translates to:
  /// **'No previous purchases found'**
  String get noPreviousPurchases;

  /// Premium coming soon message
  ///
  /// In en, this message translates to:
  /// **'Premium subscription coming soon!'**
  String get premiumComingSoon;

  /// Coming soon title for features not yet available
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Message shown when user taps AI camera feature
  ///
  /// In en, this message translates to:
  /// **'AI fish recognition is coming soon! Stay tuned for updates.'**
  String get aiCameraComingSoonMessage;

  /// This week label
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// This month label
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// 6 months label
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get sixMonths;

  /// First feeding achievement title
  ///
  /// In en, this message translates to:
  /// **'First Feeding'**
  String get achievementFirstFeeding;

  /// First feeding achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete your first feeding'**
  String get achievementFirstFeedingDesc;

  /// 7-day streak achievement title
  ///
  /// In en, this message translates to:
  /// **'Weekly Streak'**
  String get achievementStreak7;

  /// 7-day streak achievement description
  ///
  /// In en, this message translates to:
  /// **'7 consecutive days of feeding'**
  String get achievementStreak7Desc;

  /// 30-day streak achievement title
  ///
  /// In en, this message translates to:
  /// **'Monthly Streak'**
  String get achievementStreak30;

  /// 30-day streak achievement description
  ///
  /// In en, this message translates to:
  /// **'30 consecutive days of feeding'**
  String get achievementStreak30Desc;

  /// 100-day streak achievement title
  ///
  /// In en, this message translates to:
  /// **'Legendary Streak'**
  String get achievementStreak100;

  /// 100-day streak achievement description
  ///
  /// In en, this message translates to:
  /// **'100 consecutive days of feeding'**
  String get achievementStreak100Desc;

  /// Perfect week achievement title
  ///
  /// In en, this message translates to:
  /// **'Perfect Week'**
  String get achievementPerfectWeek;

  /// Perfect week achievement description
  ///
  /// In en, this message translates to:
  /// **'No missed feedings for a whole week'**
  String get achievementPerfectWeekDesc;

  /// 100 feedings achievement title
  ///
  /// In en, this message translates to:
  /// **'Century Feeder'**
  String get achievementFeedings100;

  /// 100 feedings achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete 100 total feedings'**
  String get achievementFeedings100Desc;

  /// 50 feedings achievement title
  ///
  /// In en, this message translates to:
  /// **'Dedicated Caretaker'**
  String get achievementFeedings50;

  /// 50 feedings achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete 50 total feedings'**
  String get achievementFeedings50Desc;

  /// 500 feedings achievement title
  ///
  /// In en, this message translates to:
  /// **'Feeding Master'**
  String get achievementFeedings500;

  /// 500 feedings achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete 500 total feedings'**
  String get achievementFeedings500Desc;

  /// 1000 feedings achievement title
  ///
  /// In en, this message translates to:
  /// **'Fish Whisperer'**
  String get achievementFeedings1000;

  /// 1000 feedings achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete 1000 total feedings'**
  String get achievementFeedings1000Desc;

  /// 365-day streak achievement title
  ///
  /// In en, this message translates to:
  /// **'Year-Long Streak'**
  String get achievementStreak365;

  /// 365-day streak achievement description
  ///
  /// In en, this message translates to:
  /// **'365 consecutive days of feeding'**
  String get achievementStreak365Desc;

  /// Early bird achievement title
  ///
  /// In en, this message translates to:
  /// **'Early Bird'**
  String get achievementEarlyBird;

  /// Early bird achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete a feeding before 7:00 AM'**
  String get achievementEarlyBirdDesc;

  /// Night owl achievement title
  ///
  /// In en, this message translates to:
  /// **'Night Owl'**
  String get achievementNightOwl;

  /// Night owl achievement description
  ///
  /// In en, this message translates to:
  /// **'Complete a feeding after 10:00 PM'**
  String get achievementNightOwlDesc;

  /// First fish achievement title
  ///
  /// In en, this message translates to:
  /// **'First Fish'**
  String get achievementFirstFish;

  /// First fish achievement description
  ///
  /// In en, this message translates to:
  /// **'Add your first fish'**
  String get achievementFirstFishDesc;

  /// 10 fish collector achievement title
  ///
  /// In en, this message translates to:
  /// **'Fish Collector'**
  String get achievementFishCollector10;

  /// 10 fish collector achievement description
  ///
  /// In en, this message translates to:
  /// **'Collect 10 fish'**
  String get achievementFishCollector10Desc;

  /// 50 fish collector achievement title
  ///
  /// In en, this message translates to:
  /// **'Master Collector'**
  String get achievementFishCollector50;

  /// 50 fish collector achievement description
  ///
  /// In en, this message translates to:
  /// **'Collect 50 fish'**
  String get achievementFishCollector50Desc;

  /// 5 species explorer achievement title
  ///
  /// In en, this message translates to:
  /// **'Species Explorer'**
  String get achievementSpeciesExplorer5;

  /// 5 species explorer achievement description
  ///
  /// In en, this message translates to:
  /// **'Own 5 different species'**
  String get achievementSpeciesExplorer5Desc;

  /// 10 species explorer achievement title
  ///
  /// In en, this message translates to:
  /// **'Species Expert'**
  String get achievementSpeciesExplorer10;

  /// 10 species explorer achievement description
  ///
  /// In en, this message translates to:
  /// **'Own 10 different species'**
  String get achievementSpeciesExplorer10Desc;

  /// 20 species explorer achievement title
  ///
  /// In en, this message translates to:
  /// **'Species Master'**
  String get achievementSpeciesExplorer20;

  /// 20 species explorer achievement description
  ///
  /// In en, this message translates to:
  /// **'Own 20 different species'**
  String get achievementSpeciesExplorer20Desc;

  /// First aquarium achievement title
  ///
  /// In en, this message translates to:
  /// **'First Aquarium'**
  String get achievementFirstAquarium;

  /// First aquarium achievement description
  ///
  /// In en, this message translates to:
  /// **'Create your first aquarium'**
  String get achievementFirstAquariumDesc;

  /// 3 aquariums collector achievement title
  ///
  /// In en, this message translates to:
  /// **'Aquarium Enthusiast'**
  String get achievementAquariumCollector3;

  /// 3 aquariums collector achievement description
  ///
  /// In en, this message translates to:
  /// **'Own 3 aquariums'**
  String get achievementAquariumCollector3Desc;

  /// 10 aquariums collector achievement title
  ///
  /// In en, this message translates to:
  /// **'Aquarium Empire'**
  String get achievementAquariumCollector10;

  /// 10 aquariums collector achievement description
  ///
  /// In en, this message translates to:
  /// **'Own 10 aquariums'**
  String get achievementAquariumCollector10Desc;

  /// First family member achievement title
  ///
  /// In en, this message translates to:
  /// **'Family First'**
  String get achievementFamilyFirst;

  /// First family member achievement description
  ///
  /// In en, this message translates to:
  /// **'Invite your first family member'**
  String get achievementFamilyFirstDesc;

  /// 3 family members achievement title
  ///
  /// In en, this message translates to:
  /// **'Family Team'**
  String get achievementFamilyTeam3;

  /// 3 family members achievement description
  ///
  /// In en, this message translates to:
  /// **'Have 3 family members'**
  String get achievementFamilyTeam3Desc;

  /// First share achievement title
  ///
  /// In en, this message translates to:
  /// **'Social Star'**
  String get achievementFirstShare;

  /// First share achievement description
  ///
  /// In en, this message translates to:
  /// **'Share an achievement for the first time'**
  String get achievementFirstShareDesc;

  /// Label for locked achievement
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get achievementLocked;

  /// Label for achievement that hasn't been unlocked yet
  ///
  /// In en, this message translates to:
  /// **'Not yet unlocked'**
  String get achievementNotYetUnlocked;

  /// Label showing when an achievement was unlocked
  ///
  /// In en, this message translates to:
  /// **'Unlocked {date}'**
  String achievementUnlockedOn(String date);

  /// Hint text telling user to tap to dismiss overlay
  ///
  /// In en, this message translates to:
  /// **'Tap to dismiss'**
  String get tapToDismiss;

  /// Subscription section header in settings
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscriptionSection;

  /// App section header in settings
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppSection;

  /// Account section header in settings
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSection;

  /// Legal section header in settings
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegalSection;

  /// Support section header in settings
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupportSection;

  /// Subtitle for notifications settings
  ///
  /// In en, this message translates to:
  /// **'Manage feeding reminders'**
  String get settingsNotificationsSubtitle;

  /// Subtitle for appearance settings
  ///
  /// In en, this message translates to:
  /// **'Theme and display options'**
  String get settingsAppearanceSubtitle;

  /// Subtitle for family settings
  ///
  /// In en, this message translates to:
  /// **'Invite family members to help feed'**
  String get settingsFamilySubtitle;

  /// Subtitle for delete account option
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get settingsDeleteAccountSubtitle;

  /// Privacy policy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// Subtitle for privacy policy
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get settingsPrivacyPolicySubtitle;

  /// Subtitle for terms of service
  ///
  /// In en, this message translates to:
  /// **'Usage terms and conditions'**
  String get settingsTermsSubtitle;

  /// Open source licenses menu item
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get settingsLicenses;

  /// Subtitle for licenses
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicensesSubtitle;

  /// Contact support menu item
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get settingsContactSupport;

  /// Subtitle for contact support
  ///
  /// In en, this message translates to:
  /// **'Get help via email'**
  String get settingsContactSupportSubtitle;

  /// Rate app menu item
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get settingsRateApp;

  /// Subtitle for rate app
  ///
  /// In en, this message translates to:
  /// **'Share your experience'**
  String get settingsRateAppSubtitle;

  /// App version menu item
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// Delete account confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.'**
  String get deleteAccountMessage;

  /// Header for list of things that will be deleted
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete:'**
  String get deleteAccountWillDelete;

  /// Aquariums data deletion warning
  ///
  /// In en, this message translates to:
  /// **'All your aquariums and fish data'**
  String get deleteAccountDataAquariums;

  /// History data deletion warning
  ///
  /// In en, this message translates to:
  /// **'Your feeding history and streaks'**
  String get deleteAccountDataHistory;

  /// Account data deletion warning
  ///
  /// In en, this message translates to:
  /// **'Your account and personal information'**
  String get deleteAccountDataAccount;

  /// Irreversible action warning
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible.'**
  String get deleteAccountIrreversible;

  /// Error when URL cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// Error when app store cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Could not open app store'**
  String get couldNotOpenAppStore;

  /// Success message for purchase restore
  ///
  /// In en, this message translates to:
  /// **'Purchases restored successfully'**
  String get purchasesRestoredSuccess;

  /// Error message for purchase restore failure
  ///
  /// In en, this message translates to:
  /// **'Failed to restore purchases'**
  String get failedToRestorePurchases;

  /// Subtitle for restore purchases
  ///
  /// In en, this message translates to:
  /// **'Recover previous purchases'**
  String get restorePurchasesSubtitle;

  /// Label when trial is active
  ///
  /// In en, this message translates to:
  /// **'Trial active'**
  String get subscriptionTrialActive;

  /// Trial ending message
  ///
  /// In en, this message translates to:
  /// **'Trial ends in {days} days'**
  String subscriptionTrialEndsIn(int days);

  /// Subscription renewal date
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String subscriptionRenewsOn(String date);

  /// Subscription expiration date
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String subscriptionExpiresOn(String date);

  /// Label for active subscription
  ///
  /// In en, this message translates to:
  /// **'Active subscription'**
  String get subscriptionActive;

  /// Label when ads are removed
  ///
  /// In en, this message translates to:
  /// **'Ads removed'**
  String get subscriptionAdsRemoved;

  /// Label for free plan
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get subscriptionFreePlan;

  /// Choose photo modal title
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhoto;

  /// Placeholder when no nickname is set
  ///
  /// In en, this message translates to:
  /// **'Set your nickname'**
  String get setYourNickname;

  /// Edit nickname tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit nickname'**
  String get editNickname;

  /// Nickname input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get enterYourNickname;

  /// Permission denied error message
  ///
  /// In en, this message translates to:
  /// **'Camera or gallery permission denied. Please enable it in settings.'**
  String get permissionDenied;

  /// Image picker failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image. Please try again.'**
  String get failedToPickImage;

  /// Text for sharing profile
  ///
  /// In en, this message translates to:
  /// **'Check out my FishFeed profile! I\'m {userName} on FishFeed - the best aquarium management app.'**
  String shareProfileText(String userName);

  /// View premium button
  ///
  /// In en, this message translates to:
  /// **'View Premium'**
  String get viewPremium;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// Temporary message for unimplemented feature
  ///
  /// In en, this message translates to:
  /// **'Account deletion is not yet implemented'**
  String get accountDeletionNotImplemented;

  /// Message when new events are received from server during sync
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new event received from server} other{{count} new events received from server}}'**
  String syncNewEventsReceived(int count);

  /// Message when events are deleted by server during sync
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event deleted from server} other{{count} events deleted from server}}'**
  String syncEventsDeleted(int count);

  /// Message when sync conflicts are detected
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conflict requires attention} other{{count} conflicts require attention}}'**
  String syncConflictsDetected(int count);

  /// Message when server version is chosen in conflict resolution
  ///
  /// In en, this message translates to:
  /// **'Server version applied'**
  String get syncServerWins;

  /// Message when local version is chosen in conflict resolution
  ///
  /// In en, this message translates to:
  /// **'Your version kept'**
  String get syncLocalWins;

  /// Label for aquarium name field
  ///
  /// In en, this message translates to:
  /// **'Aquarium Name'**
  String get aquariumName;

  /// Hint for aquarium name input
  ///
  /// In en, this message translates to:
  /// **'e.g., Living Room Tank'**
  String get aquariumNameHint;

  /// Validation error for aquarium name too long
  ///
  /// In en, this message translates to:
  /// **'Name must be 50 characters or less'**
  String get aquariumNameTooLong;

  /// Description for aquarium name step
  ///
  /// In en, this message translates to:
  /// **'Give your aquarium a name to easily identify it'**
  String get aquariumNameDescription;

  /// Title for first aquarium creation step
  ///
  /// In en, this message translates to:
  /// **'Create Your First Aquarium'**
  String get createYourFirstAquarium;

  /// Title/button for adding another aquarium
  ///
  /// In en, this message translates to:
  /// **'Add Another Aquarium'**
  String get addAnotherAquarium;

  /// Label for water type selector
  ///
  /// In en, this message translates to:
  /// **'Water Type'**
  String get waterType;

  /// Freshwater option
  ///
  /// In en, this message translates to:
  /// **'Freshwater'**
  String get freshwater;

  /// Saltwater option
  ///
  /// In en, this message translates to:
  /// **'Saltwater'**
  String get saltwater;

  /// Count of created aquariums
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 aquarium created} other{{count} aquariums created}}'**
  String aquariumsCreated(int count);

  /// Title for completion step
  ///
  /// In en, this message translates to:
  /// **'Aquarium Setup Complete!'**
  String get aquariumSetupComplete;

  /// Question asking if user wants to add more aquariums
  ///
  /// In en, this message translates to:
  /// **'Would you like to add another aquarium?'**
  String get addMoreAquariumQuestion;

  /// Label for previously created aquariums
  ///
  /// In en, this message translates to:
  /// **'Previously created'**
  String get previouslyCreated;

  /// Total aquarium count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 aquarium total} other{{count} aquariums total}}'**
  String totalAquariums(int count);

  /// Badge for just created aquarium
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get justCreated;

  /// Fish count with species count
  ///
  /// In en, this message translates to:
  /// **'{fishCount} fish ({speciesCount} species)'**
  String fishCountWithSpecies(int fishCount, int speciesCount);

  /// Error message when aquarium creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create aquarium. Please try again.'**
  String get failedToCreateAquarium;

  /// Placeholder text for aquarium name input
  ///
  /// In en, this message translates to:
  /// **'Enter your aquarium name'**
  String get enterAquariumName;

  /// Button to create a new aquarium
  ///
  /// In en, this message translates to:
  /// **'Create Aquarium'**
  String get createAquarium;

  /// Button to finish the onboarding setup
  ///
  /// In en, this message translates to:
  /// **'Finish Setup'**
  String get finishSetup;

  /// Default name for migrated aquarium
  ///
  /// In en, this message translates to:
  /// **'My Aquarium'**
  String get myDefaultAquarium;

  /// Button to add a new aquarium
  ///
  /// In en, this message translates to:
  /// **'Add Aquarium'**
  String get addAquarium;

  /// Success message when aquarium is created
  ///
  /// In en, this message translates to:
  /// **'Aquarium created!'**
  String get aquariumCreated;

  /// Loading message during data migration
  ///
  /// In en, this message translates to:
  /// **'Migrating your data...'**
  String get migratingData;

  /// Summary of created aquariums
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You created 1 aquarium} other{You created {count} aquariums}}'**
  String aquariumSummary(int count);

  /// Empty state when aquarium has no scheduled feedings
  ///
  /// In en, this message translates to:
  /// **'No feedings scheduled'**
  String get noFeedingsForAquarium;

  /// Title for aquarium selection
  ///
  /// In en, this message translates to:
  /// **'Select Aquarium'**
  String get selectAquarium;

  /// Description for aquarium selection step when adding fish
  ///
  /// In en, this message translates to:
  /// **'Choose which aquarium to add your fish to'**
  String get selectAquariumDescription;

  /// Label for a newly created aquarium
  ///
  /// In en, this message translates to:
  /// **'New Aquarium'**
  String get newAquarium;

  /// Title for aquarium edit screen
  ///
  /// In en, this message translates to:
  /// **'Edit Aquarium'**
  String get editAquarium;

  /// Subtitle for aquarium edit screen
  ///
  /// In en, this message translates to:
  /// **'Edit aquarium settings'**
  String get editAquariumDetails;

  /// Section title showing fish count in aquarium
  ///
  /// In en, this message translates to:
  /// **'Fish ({count})'**
  String fishInAquarium(int count);

  /// Button to delete aquarium
  ///
  /// In en, this message translates to:
  /// **'Delete Aquarium'**
  String get deleteAquarium;

  /// Title for delete aquarium confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteAquariumTitle(String name);

  /// Confirmation message for deleting aquarium
  ///
  /// In en, this message translates to:
  /// **'This will remove all fish and feeding history. This action cannot be undone.'**
  String get deleteAquariumConfirmation;

  /// Success message when aquarium is deleted
  ///
  /// In en, this message translates to:
  /// **'Aquarium deleted'**
  String get aquariumDeleted;

  /// Success message when aquarium is updated
  ///
  /// In en, this message translates to:
  /// **'Aquarium updated'**
  String get aquariumUpdated;

  /// Error message when aquarium update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update aquarium'**
  String get failedToUpdateAquarium;

  /// Error message when aquarium deletion fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete aquarium'**
  String get failedToDeleteAquarium;

  /// Error title when aquarium is not found
  ///
  /// In en, this message translates to:
  /// **'Aquarium not found'**
  String get aquariumNotFound;

  /// Error description when aquarium is not found
  ///
  /// In en, this message translates to:
  /// **'The aquarium you\'re looking for doesn\'t exist or has been deleted.'**
  String get aquariumNotFoundDescription;

  /// Empty state when aquarium has no fish
  ///
  /// In en, this message translates to:
  /// **'No fish in this aquarium'**
  String get noFishInAquarium;

  /// Description for empty fish state in aquarium
  ///
  /// In en, this message translates to:
  /// **'Add your first fish to get started'**
  String get addFishToAquarium;

  /// Count of feedings scheduled for today in aquarium section
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No feedings today} =1{1 feeding today} other{{count} feedings today}}'**
  String feedingsTodayCount(int count);

  /// Confirmation dialog title when marking feeding as done
  ///
  /// In en, this message translates to:
  /// **'Mark as fed?'**
  String get markAsFedQuestion;

  /// Confirmation button text for marking feeding as done
  ///
  /// In en, this message translates to:
  /// **'Yes, Fed'**
  String get yesFed;

  /// Label showing when a feeding was completed
  ///
  /// In en, this message translates to:
  /// **'Fed at {time}'**
  String fedAtTime(String time);

  /// Label shown when a feeding log is pending sync
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get pendingSync;

  /// Status text for aquarium with overdue feeding
  ///
  /// In en, this message translates to:
  /// **'Pending feeding at {time}'**
  String pendingFeedingAt(String time);

  /// Status text when all feedings for today are completed
  ///
  /// In en, this message translates to:
  /// **'All fed'**
  String get allFedToday;

  /// Status text showing next scheduled feeding time
  ///
  /// In en, this message translates to:
  /// **'Next at {time}'**
  String nextFeedingAt(String time);

  /// Label for portion hint in feeding detail sheet
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get portionHintLabel;

  /// Title for feeding detail bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Feeding Details'**
  String get feedingDetails;

  /// Close button text for bottom sheets and dialogs
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Toast message when another family member already marked this feeding
  ///
  /// In en, this message translates to:
  /// **'{name} already fed at {time}'**
  String feedingAlreadyDoneByMember(String name, String time);

  /// Morning greeting (before noon)
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// Afternoon greeting (noon to 6pm)
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// Evening greeting (after 6pm)
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// Greeting with user name
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}!'**
  String greetingWithName(String greeting, String name);

  /// Paywall headline
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium'**
  String get paywallUnlockPremium;

  /// Paywall subtitle
  ///
  /// In en, this message translates to:
  /// **'Get the most out of FishFeed with premium features'**
  String get paywallSubtitle;

  /// Paywall benefits section title
  ///
  /// In en, this message translates to:
  /// **'Premium Benefits'**
  String get paywallPremiumBenefits;

  /// Paywall plan selection title
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get paywallChooseYourPlan;

  /// Annual plan title
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get paywallAnnual;

  /// Monthly plan title
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// Badge for best value plan
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get paywallBestValue;

  /// Subtitle for monthly plan
  ///
  /// In en, this message translates to:
  /// **'Most Flexible'**
  String get paywallMostFlexible;

  /// Savings percentage badge
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywallSavePercent(int percent);

  /// CTA button text for free trial
  ///
  /// In en, this message translates to:
  /// **'Start 7-Day Free Trial'**
  String get paywallStartFreeTrial;

  /// Trial terms disclaimer for iOS (App Store cancellation)
  ///
  /// In en, this message translates to:
  /// **'Free trial for 7 days, then auto-renews at the selected plan price. Cancel anytime in App Store settings.'**
  String get paywallTrialTermsIos;

  /// Trial terms disclaimer for Android (Google Play cancellation)
  ///
  /// In en, this message translates to:
  /// **'Free trial for 7 days, then auto-renews at the selected plan price. Cancel anytime in Google Play settings.'**
  String get paywallTrialTermsAndroid;

  /// Error when products cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get paywallFailedToLoadProducts;

  /// Error when purchase fails
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get paywallPurchaseFailed;

  /// Divider text between premium and remove ads sections
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get paywallOr;

  /// Price per month display
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String paywallPerMonth(String price);

  /// Price per year display
  ///
  /// In en, this message translates to:
  /// **'{price}/year'**
  String paywallPerYear(String price);

  /// Premium benefit: extended statistics
  ///
  /// In en, this message translates to:
  /// **'Extended Statistics (6 months)'**
  String get paywallExtendedStatistics;

  /// Premium benefit: family mode
  ///
  /// In en, this message translates to:
  /// **'Family Mode (5+ users)'**
  String get paywallFamilyMode;

  /// Premium benefit: multiple aquariums
  ///
  /// In en, this message translates to:
  /// **'Multiple Aquariums'**
  String get paywallMultipleAquariums;

  /// Premium benefit: unlimited AI scans
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Fish Scans'**
  String get paywallUnlimitedAiScans;

  /// Snackbar message when trying to mark a feeding that is already done
  ///
  /// In en, this message translates to:
  /// **'This feeding has already been completed'**
  String get feedingAlreadyCompleted;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Image upload progress indicator text
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get imageUploadProgress;

  /// Image upload failure message with retry hint
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Tap to retry.'**
  String get imageUploadError;

  /// Confirmation dialog text for removing a photo
  ///
  /// In en, this message translates to:
  /// **'Remove this photo?'**
  String get imageDeleteConfirm;

  /// Button label for removing a photo
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get imageDeleteButton;

  /// Placeholder text when no image is set
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get imagePlaceholder;

  /// Button label for retrying a failed image upload
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get imageRetryButton;

  /// Aquarium label
  ///
  /// In en, this message translates to:
  /// **'Aquarium'**
  String get aquarium;

  /// Title for aquarium details screen
  ///
  /// In en, this message translates to:
  /// **'Aquarium Details'**
  String get aquariumDetails;

  /// Title for fish details screen
  ///
  /// In en, this message translates to:
  /// **'Fish Details'**
  String get fishDetails;

  /// Volume label for aquarium
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// Brackish water type
  ///
  /// In en, this message translates to:
  /// **'Brackish'**
  String get brackish;

  /// Feeding schedule section title
  ///
  /// In en, this message translates to:
  /// **'Feeding Schedule'**
  String get feedingSchedule;

  /// Notes section title
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Placeholder text for notes input
  ///
  /// In en, this message translates to:
  /// **'Add notes about this fish...'**
  String get addNotes;

  /// Species label
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get species;

  /// Label for date when item was added
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// Confirmation message for deleting a fish
  ///
  /// In en, this message translates to:
  /// **'Delete this fish?'**
  String get deleteFishConfirm;

  /// Message when fish is moved to another aquarium
  ///
  /// In en, this message translates to:
  /// **'Moved to {aquariumName}'**
  String fishMovedTo(String aquariumName);

  /// View action button text
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// Confirmation message for deleting an aquarium
  ///
  /// In en, this message translates to:
  /// **'Delete this aquarium?'**
  String get deleteAquariumConfirm;

  /// Button text for marking a feeding as completed
  ///
  /// In en, this message translates to:
  /// **'Mark as Fed'**
  String get markAsFedButton;

  /// Body text for delete fish confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will remove the fish and deactivate all its feeding schedules. This action cannot be undone.'**
  String get deleteFishBody;

  /// Feeding interval label for every day
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get intervalDaily;

  /// Feeding interval label for every 7 days
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get intervalWeekly;

  /// Feeding interval label for every N days
  ///
  /// In en, this message translates to:
  /// **'Every {count} days'**
  String intervalEveryNDays(int count);

  /// Button text for editing a fish
  ///
  /// In en, this message translates to:
  /// **'Edit Fish'**
  String get editFishButton;

  /// Label for scheduled feeding time
  ///
  /// In en, this message translates to:
  /// **'Scheduled Time'**
  String get scheduledTime;

  /// Food type label for flakes
  ///
  /// In en, this message translates to:
  /// **'Flakes'**
  String get foodTypeFlakes;

  /// Food type label for pellets
  ///
  /// In en, this message translates to:
  /// **'Pellets'**
  String get foodTypePellets;

  /// Food type label for frozen food
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get foodTypeFrozen;

  /// Food type label for live food
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get foodTypeLive;

  /// Food type label for mixed food
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get foodTypeMixed;

  /// Label for feeding interval selector
  ///
  /// In en, this message translates to:
  /// **'Feeding Interval'**
  String get feedingInterval;

  /// Label for feeding times section
  ///
  /// In en, this message translates to:
  /// **'Feeding Times'**
  String get feedingTimes;

  /// Button label for adding a feeding time
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get addFeedingTime;

  /// Placeholder text for portion hint input
  ///
  /// In en, this message translates to:
  /// **'e.g. 2 pinches, 3 pellets'**
  String get portionHintPlaceholder;

  /// Label for every-other-day feeding interval
  ///
  /// In en, this message translates to:
  /// **'Every 2 Days'**
  String get everyOtherDay;

  /// Description for system theme mode
  ///
  /// In en, this message translates to:
  /// **'Automatically matches your device settings'**
  String get themeDescriptionSystem;

  /// Description for light theme mode
  ///
  /// In en, this message translates to:
  /// **'Always use light theme'**
  String get themeDescriptionLight;

  /// Description for dark theme mode
  ///
  /// In en, this message translates to:
  /// **'Always use dark theme'**
  String get themeDescriptionDark;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// German language name
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// English language native name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishNative;

  /// German language native name
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGermanNative;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Info text about notification preferences sync
  ///
  /// In en, this message translates to:
  /// **'Notification preferences are saved locally and will be synced with your account when online.'**
  String get notificationPreferencesSavedLocally;

  /// Master toggle title for notifications
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// Subtitle when notifications are enabled
  ///
  /// In en, this message translates to:
  /// **'Receive feeding reminders and alerts'**
  String get receiveRemindersAndAlerts;

  /// Subtitle when notifications are disabled
  ///
  /// In en, this message translates to:
  /// **'All notifications are disabled'**
  String get allNotificationsDisabled;

  /// Section header for notification types
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notificationTypes;

  /// Notification type title
  ///
  /// In en, this message translates to:
  /// **'Feeding Reminders'**
  String get feedingReminders;

  /// Subtitle for feeding reminders toggle
  ///
  /// In en, this message translates to:
  /// **'Get notified when it\'s time to feed'**
  String get feedingRemindersSubtitle;

  /// Notification type title
  ///
  /// In en, this message translates to:
  /// **'Streak Alerts'**
  String get streakAlerts;

  /// Subtitle for streak alerts toggle
  ///
  /// In en, this message translates to:
  /// **'Warnings when your streak is at risk'**
  String get streakAlertsSubtitle;

  /// Notification type title
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// Subtitle for weekly summary toggle
  ///
  /// In en, this message translates to:
  /// **'Weekly feeding activity overview'**
  String get weeklySummarySubtitle;

  /// Section header for quiet hours
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get quietHours;

  /// Toggle title for quiet hours
  ///
  /// In en, this message translates to:
  /// **'Enable Quiet Hours'**
  String get enableQuietHours;

  /// Subtitle for quiet hours toggle
  ///
  /// In en, this message translates to:
  /// **'Mute notifications during specified hours'**
  String get muteNotificationsDuringHours;

  /// Notification title for feeding time
  ///
  /// In en, this message translates to:
  /// **'Feeding Time!'**
  String get feedingTimeNotificationTitle;

  /// Notification body for feeding time
  ///
  /// In en, this message translates to:
  /// **'Time to feed your {speciesText}'**
  String feedingTimeNotificationBody(String speciesText);

  /// Error message when image fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// Badge label for photo preview
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Button label while processing
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Button label to use captured photo
  ///
  /// In en, this message translates to:
  /// **'Use Photo'**
  String get usePhoto;

  /// Loading overlay text during image preparation
  ///
  /// In en, this message translates to:
  /// **'Preparing image...'**
  String get preparingImage;

  /// Error message when image processing fails
  ///
  /// In en, this message translates to:
  /// **'Failed to process image'**
  String get failedToProcessImage;

  /// Badge label for AI scan result
  ///
  /// In en, this message translates to:
  /// **'AI Result'**
  String get aiResult;

  /// Warning when AI confidence is low
  ///
  /// In en, this message translates to:
  /// **'Low confidence. Please verify or select manually.'**
  String get lowConfidenceWarning;

  /// Care level label
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get careLevelBeginner;

  /// Care level label
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get careLevelIntermediate;

  /// Care level label
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get careLevelAdvanced;

  /// Feeding frequency label
  ///
  /// In en, this message translates to:
  /// **'Once daily'**
  String get feedingFreqOnceDaily;

  /// Feeding frequency label
  ///
  /// In en, this message translates to:
  /// **'Twice daily'**
  String get feedingFreqTwiceDaily;

  /// Feeding frequency label
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get feedingFreqDaily;

  /// Feeding frequency label
  ///
  /// In en, this message translates to:
  /// **'Every other day'**
  String get feedingFreqEveryOtherDay;

  /// Section header for AI recommendations
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
