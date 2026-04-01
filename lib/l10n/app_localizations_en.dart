// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FishFeed';

  @override
  String get welcomeMessage => 'Welcome to FishFeed';

  @override
  String get loginButton => 'Log In';

  @override
  String get registerButton => 'Register';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get calendar => 'Calendar';

  @override
  String get home => 'Home';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get logout => 'Log Out';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get invalidPasswordFormat =>
      'Password must be at least 8 characters with 1 number and 1 uppercase letter';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get agreeToTermsPrefix => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get tosCheckboxRequired => 'You must agree to the Terms of Service';

  @override
  String get passwordWeak => 'Weak';

  @override
  String get passwordMedium => 'Medium';

  @override
  String get passwordStrong => 'Strong';

  @override
  String get createAccount => 'Create Account';

  @override
  String get errorNoConnection =>
      'No internet connection. Please check your network.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorInvalidCredentials =>
      'Invalid email or password. Please try again.';

  @override
  String get errorValidation => 'Please check your input and try again.';

  @override
  String get errorOAuth => 'Sign in failed. Please try again.';

  @override
  String get errorGoogleSignIn => 'Google sign in failed. Please try again.';

  @override
  String get errorAppleSignIn => 'Apple sign in failed. Please try again.';

  @override
  String get errorOperationCancelled => 'Operation was cancelled.';

  @override
  String get errorLocalStorage =>
      'Local storage error. Please restart the app.';

  @override
  String get errorUnexpected =>
      'An unexpected error occurred. Please try again.';

  @override
  String get successLogin => 'Welcome back!';

  @override
  String get successRegister => 'Account created successfully!';

  @override
  String get successLogout => 'You have been logged out.';

  @override
  String get notificationPermissionTitle => 'Enable Notifications';

  @override
  String get notificationPermissionDescription =>
      'Get timely reminders to feed your fish. We\'ll notify you at scheduled feeding times so you never miss a meal.';

  @override
  String get notificationPermissionEnable => 'Enable Notifications';

  @override
  String get notificationPermissionLater => 'Later';

  @override
  String get notificationsBannerTitle => 'Notifications Disabled';

  @override
  String get notificationsBannerDescription =>
      'Enable notifications to receive feeding reminders';

  @override
  String get notificationsBannerAction => 'Enable';

  @override
  String get notificationsSettingsTitle => 'Notifications';

  @override
  String get notificationsSettingsOpenSettings => 'Open Settings';

  @override
  String get notificationsSettingsDisabledHint =>
      'Notifications are disabled. Tap to open settings and enable them.';

  @override
  String get freezeDayDialogTitle => 'Missed Feeding';

  @override
  String get freezeDayDialogDescription =>
      'You missed feeding your fish today. Use a freeze day to protect your streak!';

  @override
  String get freezeDayDialogNoFreezeDescription =>
      'You missed feeding your fish today and have no freeze days left. Your streak will be reset.';

  @override
  String freezeDayDialogStreakAtRisk(int count) {
    return '$count day streak at risk';
  }

  @override
  String freezeDayDialogUseFreeze(int count) {
    return 'Use Freeze Day ($count left)';
  }

  @override
  String get freezeDayDialogLoseStreak => 'Lose Streak';

  @override
  String get freezeIndicatorTooltipNone => 'No freeze days left this month';

  @override
  String get freezeIndicatorTooltipOne => '1 freeze day available';

  @override
  String freezeIndicatorTooltipMany(int count) {
    return '$count freeze days available';
  }

  @override
  String get freezeWarningNotificationTitle => 'Streak at Risk!';

  @override
  String freezeWarningNotificationBody(int freezeCount, int streakCount) {
    return 'You have $freezeCount freeze day(s) available to protect your $streakCount day streak!';
  }

  @override
  String get emptyStateTodayTitle => 'No events today';

  @override
  String get emptyStateTodayDescription =>
      'All your fish are fed! Enjoy the day.';

  @override
  String get emptyStateFishListTitle => 'No fish yet';

  @override
  String get emptyStateFishListDescription =>
      'Add your first fish to start tracking feeding schedules.';

  @override
  String get emptyStateFishListAction => 'Add Fish';

  @override
  String get emptyStateAchievementsTitle => 'No achievements yet';

  @override
  String get emptyStateAchievementsDescription =>
      'Start feeding your fish regularly to unlock achievements!';

  @override
  String get emptyStateCalendarTitle => 'No feeding history';

  @override
  String get emptyStateCalendarDescription =>
      'Start tracking feedings to see your history here.';

  @override
  String get errorStateNetworkTitle => 'No connection';

  @override
  String get errorStateNetworkDescription =>
      'Please check your internet connection and try again.';

  @override
  String get errorStateServerTitle => 'Something went wrong';

  @override
  String get errorStateServerDescription =>
      'We\'re having trouble connecting. Please try again later.';

  @override
  String get errorStateTimeoutTitle => 'Server not responding';

  @override
  String get errorStateTimeoutDescription =>
      'The request took too long. Please try again.';

  @override
  String get errorStateGenericTitle => 'Oops!';

  @override
  String get errorStateGenericDescription =>
      'Something went wrong. Please try again.';

  @override
  String get errorStateTryAgain => 'Try Again';

  @override
  String get errorStateContactSupport => 'Contact Support';

  @override
  String get offlineBannerTitle => 'You\'re offline';

  @override
  String get offlineBannerDescription => 'Some features may not be available';

  @override
  String get lowStorageTitle => 'Storage Low';

  @override
  String lowStorageDescription(int size) {
    return 'Your device has less than $size MB of free storage. Some features may not work properly.';
  }

  @override
  String get lowStorageClearCache => 'Clear Cache';

  @override
  String get lowStorageDismiss => 'Got it';

  @override
  String get cacheCleared => 'Cache cleared successfully';

  @override
  String fishCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fish',
      one: '1 fish',
      zero: 'No fish',
    );
    return '$_temp0';
  }

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String achievementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count achievements',
      one: '1 achievement',
      zero: 'No achievements',
    );
    return '$_temp0';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
      zero: '0 day streak',
    );
    return '$_temp0';
  }

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncStatusSyncing => 'Syncing...';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusError => 'Sync failed';

  @override
  String get syncStatusJustNow => 'Just now';

  @override
  String syncStatusMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String syncStatusHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String syncStatusDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get syncCannotSyncOffline => 'Cannot sync while offline';

  @override
  String get conflictDialogTitle => 'Sync Conflict';

  @override
  String get conflictDialogDescription =>
      'This item was modified on another device. Choose which version to keep.';

  @override
  String get conflictDifferingFields => 'Changed fields:';

  @override
  String get conflictLocalVersion => 'Your version';

  @override
  String get conflictServerVersion => 'Server version';

  @override
  String get conflictKeepMyVersion => 'Keep mine';

  @override
  String get conflictUseServerVersion => 'Use server';

  @override
  String get conflictDeletionTitle => 'Deletion Conflict';

  @override
  String get conflictDeletionDescription =>
      'This item was deleted on another device but you made changes locally. Choose whether to restore or delete it.';

  @override
  String get conflictRestoreItem => 'Restore';

  @override
  String get conflictDeleteItem => 'Delete';

  @override
  String conflictDeletedOn(String date) {
    return 'Deleted on $date';
  }

  @override
  String get myAquarium => 'My Aquarium';

  @override
  String get manageFish => 'Manage';

  @override
  String get addFish => 'Add Fish';

  @override
  String get editFish => 'Edit Fish';

  @override
  String get deleteFish => 'Delete';

  @override
  String deleteFishTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get confirmDeleteFish =>
      'This will remove the fish and its feeding schedule.';

  @override
  String get fishQuantity => 'Quantity';

  @override
  String get customName => 'Custom Name';

  @override
  String get customNameHint => 'Give your fish a name';

  @override
  String get customNameOptional => 'Optional - leave blank to use species name';

  @override
  String get emptyAquarium => 'No fish yet';

  @override
  String get addFirstFish => 'Add your first fish';

  @override
  String get addFirstFishDescription =>
      'Add your first fish to start tracking feedings';

  @override
  String fishAddedSuccessfully(String name) {
    return '$name added successfully';
  }

  @override
  String get fishDeletedSuccessfully => 'Fish deleted';

  @override
  String get fishUpdatedSuccessfully => 'Changes saved';

  @override
  String moreCount(int count) {
    return '+$count more';
  }

  @override
  String get addFishTooltip => 'Add fish';

  @override
  String get editFishDetails => 'Edit fish details';

  @override
  String get fishNotFound => 'Fish not found';

  @override
  String get fishNotFoundDescription =>
      'The fish you are trying to edit no longer exists.';

  @override
  String get goBack => 'Go back';

  @override
  String get failedToSaveChanges => 'Failed to save changes. Please try again.';

  @override
  String get scanWithAiCamera => 'Scan with AI Camera';

  @override
  String get takePhotoToIdentify => 'Take a photo to identify fish species';

  @override
  String get selectFromList => 'Select from list';

  @override
  String get chooseFromSpeciesList => 'Choose from available species';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get feedingsLabel => 'Feedings';

  @override
  String get daysWithApp => 'Days with FishFeed';

  @override
  String get onTimeLabel => 'On time';

  @override
  String get levelLabel => 'Level';

  @override
  String get experienceLabel => 'Experience';

  @override
  String get streakTitle => 'Streak';

  @override
  String get currentStreakLabel => 'Current streak';

  @override
  String get bestStreakLabel => 'Best';

  @override
  String get freezeLabel => 'Freeze';

  @override
  String get freezeDaysTitle => 'Freeze Days';

  @override
  String get freezeDaysDescription =>
      'Freeze days protect your streak when you miss a feeding.';

  @override
  String freezeDaysPerMonth(int count) {
    return 'You get $count freeze days per month';
  }

  @override
  String get freezeDaysAutoUsed =>
      'Freeze is used automatically when you miss a day';

  @override
  String freezeDaysAvailable(int count) {
    return 'Available freeze days: $count';
  }

  @override
  String get watchAdForFreezeDay => 'Watch Ad for +1 Freeze Day';

  @override
  String get freezeDayEarned => 'You earned +1 freeze day!';

  @override
  String get gotItButton => 'Got it';

  @override
  String milestoneDays(int count) {
    return '$count days';
  }

  @override
  String streakDaysInRow(int count) {
    return '$count days in a row!';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementFailedToLoad => 'Failed to load achievements';

  @override
  String get achievementCompleteToUnlock => 'Complete the challenge to unlock';

  @override
  String get progressLabel => 'Progress';

  @override
  String get shareButton => 'Share';

  @override
  String get sharingButton => 'Sharing...';

  @override
  String get achievementUnlocked => 'Achievement Unlocked!';

  @override
  String get tapToClose => 'Tap to close';

  @override
  String achievementProgress(int percent) {
    return 'Progress: $percent%';
  }

  @override
  String get notUnlockedYet => 'Not unlocked yet';

  @override
  String get locked => 'Locked';

  @override
  String get achievementProgressTitle => 'Achievement Progress';

  @override
  String unlockedOn(String date) {
    return 'Unlocked $date';
  }

  @override
  String get feedingLabel => 'Feeding';

  @override
  String get feedingCompleted => 'Feeding completed!';

  @override
  String get feedingMissed => 'Missed';

  @override
  String get statusGreatJob => 'Great job!';

  @override
  String get statusNextTime => 'Next time will work!';

  @override
  String get statusPendingFeeding => 'Pending feeding';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelCaretaker => 'Caretaker';

  @override
  String get levelMaster => 'Master';

  @override
  String get levelPro => 'Pro';

  @override
  String get levelBeginnerTooltip =>
      'Beginner Aquarist - first steps in fish care';

  @override
  String get levelCaretakerTooltip =>
      'Caretaker - consistently caring for your fish';

  @override
  String get levelMasterTooltip => 'Master - experienced aquarist';

  @override
  String get levelProTooltip => 'Professional - expert in fish care!';

  @override
  String get maxLevel => 'Max Level';

  @override
  String get familyAccess => 'Family Access';

  @override
  String get familyMode => 'Family Mode';

  @override
  String get familyModeDescription =>
      'Invite family members to care for your fish together. Everyone can feed and see who fed.';

  @override
  String get activeInvitations => 'Active Invitations';

  @override
  String get familyMembers => 'Family Members';

  @override
  String membersCount(int current, int max) {
    return 'Members: $current / $max';
  }

  @override
  String get limitReached => 'Limit reached';

  @override
  String get freePlanLimitReached => 'Free plan limit reached';

  @override
  String upgradeToPremiumFamily(int count) {
    return 'Upgrade to Premium to add up to $count family members and access feeding statistics.';
  }

  @override
  String upToMembers(int count) {
    return 'Up to $count members';
  }

  @override
  String get statisticsFeature => 'Statistics';

  @override
  String get managementFeature => 'Management';

  @override
  String get goToPremium => 'Go to Premium';

  @override
  String get inviteFamilyMember => 'Invite family member';

  @override
  String get youAreOnlyMember => 'You are the only family member';

  @override
  String get inviteSomeone =>
      'Invite someone to care for the aquarium together';

  @override
  String joinMyAquarium(String link, String code) {
    return 'Join my aquarium in FishFeed!\n\nFollow the link: $link\n\nOr enter code: $code';
  }

  @override
  String get invitationToFishFeed => 'Invitation to FishFeed';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get cancelInvitation => 'Cancel invitation?';

  @override
  String get cancelInvitationDescription =>
      'This invitation can no longer be used.';

  @override
  String get no => 'No';

  @override
  String get removeMember => 'Remove member?';

  @override
  String removeMemberDescription(String name) {
    return 'Are you sure you want to remove $name?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get leaveFamily => 'Leave family?';

  @override
  String get leaveFamilyDescription =>
      'You will lose access to this shared aquarium.';

  @override
  String get leave => 'Leave';

  @override
  String get invitationCreated => 'Invitation created!';

  @override
  String validForHours(int hours) {
    return 'Valid for $hours hours';
  }

  @override
  String get invitationCode => 'Invitation code';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String validForHoursShort(int hours) {
    return 'Valid for ${hours}h';
  }

  @override
  String validForMinutesShort(int minutes) {
    return 'Valid for ${minutes}m';
  }

  @override
  String get expiring => 'Expiring';

  @override
  String get user => 'User';

  @override
  String get owner => 'Owner';

  @override
  String get member => 'Member';

  @override
  String joinedDate(String date) {
    return 'Joined: $date';
  }

  @override
  String feedingsThisWeek(int count) {
    return '$count this week';
  }

  @override
  String feedingsThisMonth(int count) {
    return '$count this month';
  }

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get joiningFamily => 'Joining family...';

  @override
  String get processingInvitation =>
      'Please wait while we process your invitation';

  @override
  String get congratulations => 'Congratulations!';

  @override
  String get joinedFamilySuccess =>
      'You have successfully joined the family aquarium';

  @override
  String get redirecting => 'Redirecting...';

  @override
  String get loginRequired => 'Login required';

  @override
  String get invitationError => 'Invitation error';

  @override
  String get loginToAcceptInvitation => 'Log in to accept the invitation';

  @override
  String get logIn => 'Log in';

  @override
  String get toHome => 'To home';

  @override
  String feedingCompletedByUser(String userName) {
    return 'Feeding completed: $userName';
  }

  @override
  String get familyMember => 'Family member';

  @override
  String get feedingDone => 'Feeding done';

  @override
  String get feedingTime => 'Feeding Time!';

  @override
  String timeToFeed(String fishName) {
    return 'Time to feed $fishName';
  }

  @override
  String get yourFish => 'your fish';

  @override
  String get eventOverdue => 'Event overdue';

  @override
  String eventOverdueFor(String fishName) {
    return 'Event overdue for $fishName';
  }

  @override
  String get confirmStatus => 'Confirm status';

  @override
  String get confirmFeedingStatus => 'Confirm feeding status';

  @override
  String get fedAction => 'Fed ✓';

  @override
  String get snoozeAction => 'Snooze 15m';

  @override
  String shareAchievementGeneric(String title) {
    return 'I got the achievement \"$title\" in FishFeed! 🐟🏆';
  }

  @override
  String get shareFirstFeeding =>
      'I started caring for fish in FishFeed! 🐟 First feeding done! 🎉';

  @override
  String get shareStreak7 =>
      'A week without misses! 🔥 My streak in FishFeed: 7 days! 🏆';

  @override
  String get shareStreak30 =>
      'A month of perfection! 🌟 30 days of feedings in a row in FishFeed! 🔥';

  @override
  String get shareStreak100 =>
      'Legendary streak! 💎 100 days of feedings without misses in FishFeed! 🏆🔥';

  @override
  String get sharePerfectWeek =>
      'Perfect week! ✨ No missed feedings in FishFeed! 🐟';

  @override
  String get shareFeedings50 =>
      'Dedicated caretaker! 🐠 50 feedings completed in FishFeed! 🎉';

  @override
  String get shareFeedings100 =>
      'A hundred feedings! 🎯 Fed my fish 100 times in FishFeed! 🐟';

  @override
  String get shareFeedings500 =>
      'Feeding master! 👑 500 feedings in FishFeed! My fish are in good hands! 🐟🏆';

  @override
  String get shareFeedings1000 =>
      'Fish whisperer! 🌊 1000 feedings in FishFeed! True dedication! 🐟💎';

  @override
  String get shareStreak365 =>
      'A full year! 🏅 365 days of feedings without misses in FishFeed! 🐟💎🔥';

  @override
  String get shareEarlyBird =>
      'Early Bird! 🌅 Fed my fish before sunrise in FishFeed! 🐟';

  @override
  String get shareNightOwl =>
      'Night Owl! 🌙 Late-night feeding in FishFeed! 🐟';

  @override
  String get shareFirstFish =>
      'My first fish! 🐟 Added my first fish to FishFeed! 🎉';

  @override
  String get shareFishCollector10 =>
      'Fish Collector! 🐠 10 fish in my FishFeed aquariums! 🏆';

  @override
  String get shareFishCollector50 =>
      'Master Collector! 🐟 50 fish in FishFeed! A true aquarist! 🏆💎';

  @override
  String get shareSpeciesExplorer5 =>
      'Species Explorer! 🔍 5 different species in FishFeed! 🐟';

  @override
  String get shareSpeciesExplorer10 =>
      'Species Expert! 🧬 10 different species in FishFeed! 🐠🏆';

  @override
  String get shareSpeciesExplorer20 =>
      'Species Master! 🌊 20 different species in FishFeed! True biodiversity! 🐟💎';

  @override
  String get shareFirstAquarium =>
      'My first aquarium! 🏠 Set up my first aquarium in FishFeed! 🐟';

  @override
  String get shareAquariumCollector3 =>
      'Aquarium Enthusiast! 🏠 3 aquariums in FishFeed! 🐟🏆';

  @override
  String get shareAquariumCollector10 =>
      'Aquarium Empire! 🏰 10 aquariums in FishFeed! A true master! 🐟💎';

  @override
  String get shareFamilyFirst =>
      'Teamwork! 👨‍👩‍👧 Invited my first family member to FishFeed! 🐟';

  @override
  String get shareFamilyTeam3 =>
      'Family Team! 👨‍👩‍👧‍👦 3 family members caring for fish in FishFeed! 🐟🏆';

  @override
  String get shareFirstShare =>
      'Shared my first achievement in FishFeed! 📢 Join me! 🐟';

  @override
  String shareStreakLong(String appName, int days) {
    return 'Incredible! 💎 My streak in $appName: $days days! 🔥🏆';
  }

  @override
  String shareStreakMedium(String appName, int days) {
    return 'Amazing! 🌟 My streak in $appName: $days days! 🔥';
  }

  @override
  String shareStreakShort(String appName, int days) {
    return 'Awesome! 🔥 My streak in $appName: $days days!';
  }

  @override
  String shareStreakDefault(String appName, int days) {
    return 'My streak in $appName: $days days! 🐟';
  }

  @override
  String get achievementUnlockedCard => 'ACHIEVEMENT UNLOCKED';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get noFeedingsScheduled => 'No feedings scheduled';

  @override
  String feedingsCompleted(int completed, int total) {
    return '$completed of $total feedings completed';
  }

  @override
  String get statusComplete => 'Complete';

  @override
  String get statusMissed => 'Missed';

  @override
  String get statusPartial => 'Partial';

  @override
  String get statusNoData => 'No data';

  @override
  String get loadingFeedings => 'Loading feedings...';

  @override
  String get allFeedingsCompleted => 'All feedings completed';

  @override
  String get allFeedingsMissed => 'All feedings missed';

  @override
  String get someFeedingsCompleted => 'Some feedings completed';

  @override
  String get noFeedingData => 'No feeding data';

  @override
  String get logoutConfirmTitle => 'Log Out';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountConfirm => 'Final Confirmation';

  @override
  String get deleteMyAccount => 'Delete My Account';

  @override
  String get subscription => 'Subscription';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get recoverPreviousPurchases => 'Recover previous purchases';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameUpdated => 'Nickname updated successfully';

  @override
  String get failedToShareProfile => 'Failed to share profile';

  @override
  String get shareProfile => 'Share Profile';

  @override
  String get premiumFeature => 'Premium feature';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get unlockAllFeatures => 'Unlock all features';

  @override
  String upgradeToUnlock(String feature) {
    return 'Upgrade to unlock $feature';
  }

  @override
  String get noAds => 'No Ads';

  @override
  String get unlimitedAiScans => 'Unlimited AI Scans';

  @override
  String get sixMonthsHistory => '6 Months History';

  @override
  String get viewPlans => 'View Plans';

  @override
  String get trial => 'Trial';

  @override
  String get premium => 'Premium';

  @override
  String get free => 'Free';

  @override
  String get goPremium => 'Go Premium';

  @override
  String get addManually => 'Add manually';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get removeAds => 'Remove Ads';

  @override
  String get oneTimePurchase => 'One-time purchase';

  @override
  String get tryPremiumFeatures => 'Try all premium features. Cancel anytime.';

  @override
  String get upgradePremiumAiScans =>
      'Upgrade to Premium for unlimited AI fish recognition';

  @override
  String get priorityProcessing => 'Priority processing';

  @override
  String get higherAccuracy => 'Higher accuracy';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get retake => 'Retake';

  @override
  String get selectManually => 'Select Manually';

  @override
  String get confirmAnyway => 'Confirm Anyway';

  @override
  String get notCorrect => 'Not correct?';

  @override
  String get confirm => 'Confirm';

  @override
  String get noScansLeft => 'No scans left';

  @override
  String get back => 'Back';

  @override
  String get foodType => 'Food type';

  @override
  String get portion => 'Portion';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get appearance => 'Appearance';

  @override
  String get welcomeToPremium => 'Welcome to Premium!';

  @override
  String get adsRemovedSuccessfully => 'Ads removed successfully!';

  @override
  String get noPreviousPurchases => 'No previous purchases found';

  @override
  String get premiumComingSoon => 'Premium subscription coming soon!';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get aiCameraComingSoonMessage =>
      'AI fish recognition is coming soon! Stay tuned for updates.';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get sixMonths => '6 Months';

  @override
  String get achievementFirstFeeding => 'First Feeding';

  @override
  String get achievementFirstFeedingDesc => 'Complete your first feeding';

  @override
  String get achievementStreak7 => 'Weekly Streak';

  @override
  String get achievementStreak7Desc => '7 consecutive days of feeding';

  @override
  String get achievementStreak30 => 'Monthly Streak';

  @override
  String get achievementStreak30Desc => '30 consecutive days of feeding';

  @override
  String get achievementStreak100 => 'Legendary Streak';

  @override
  String get achievementStreak100Desc => '100 consecutive days of feeding';

  @override
  String get achievementPerfectWeek => 'Perfect Week';

  @override
  String get achievementPerfectWeekDesc =>
      'No missed feedings for a whole week';

  @override
  String get achievementFeedings100 => 'Century Feeder';

  @override
  String get achievementFeedings100Desc => 'Complete 100 total feedings';

  @override
  String get achievementFeedings50 => 'Dedicated Caretaker';

  @override
  String get achievementFeedings50Desc => 'Complete 50 total feedings';

  @override
  String get achievementFeedings500 => 'Feeding Master';

  @override
  String get achievementFeedings500Desc => 'Complete 500 total feedings';

  @override
  String get achievementFeedings1000 => 'Fish Whisperer';

  @override
  String get achievementFeedings1000Desc => 'Complete 1000 total feedings';

  @override
  String get achievementStreak365 => 'Year-Long Streak';

  @override
  String get achievementStreak365Desc => '365 consecutive days of feeding';

  @override
  String get achievementEarlyBird => 'Early Bird';

  @override
  String get achievementEarlyBirdDesc => 'Complete a feeding before 7:00 AM';

  @override
  String get achievementNightOwl => 'Night Owl';

  @override
  String get achievementNightOwlDesc => 'Complete a feeding after 10:00 PM';

  @override
  String get achievementFirstFish => 'First Fish';

  @override
  String get achievementFirstFishDesc => 'Add your first fish';

  @override
  String get achievementFishCollector10 => 'Fish Collector';

  @override
  String get achievementFishCollector10Desc => 'Collect 10 fish';

  @override
  String get achievementFishCollector50 => 'Master Collector';

  @override
  String get achievementFishCollector50Desc => 'Collect 50 fish';

  @override
  String get achievementSpeciesExplorer5 => 'Species Explorer';

  @override
  String get achievementSpeciesExplorer5Desc => 'Own 5 different species';

  @override
  String get achievementSpeciesExplorer10 => 'Species Expert';

  @override
  String get achievementSpeciesExplorer10Desc => 'Own 10 different species';

  @override
  String get achievementSpeciesExplorer20 => 'Species Master';

  @override
  String get achievementSpeciesExplorer20Desc => 'Own 20 different species';

  @override
  String get achievementFirstAquarium => 'First Aquarium';

  @override
  String get achievementFirstAquariumDesc => 'Create your first aquarium';

  @override
  String get achievementAquariumCollector3 => 'Aquarium Enthusiast';

  @override
  String get achievementAquariumCollector3Desc => 'Own 3 aquariums';

  @override
  String get achievementAquariumCollector10 => 'Aquarium Empire';

  @override
  String get achievementAquariumCollector10Desc => 'Own 10 aquariums';

  @override
  String get achievementFamilyFirst => 'Family First';

  @override
  String get achievementFamilyFirstDesc => 'Invite your first family member';

  @override
  String get achievementFamilyTeam3 => 'Family Team';

  @override
  String get achievementFamilyTeam3Desc => 'Have 3 family members';

  @override
  String get achievementFirstShare => 'Social Star';

  @override
  String get achievementFirstShareDesc =>
      'Share an achievement for the first time';

  @override
  String get achievementLocked => 'Locked';

  @override
  String get achievementNotYetUnlocked => 'Not yet unlocked';

  @override
  String achievementUnlockedOn(String date) {
    return 'Unlocked $date';
  }

  @override
  String get tapToDismiss => 'Tap to dismiss';

  @override
  String get settingsSubscriptionSection => 'Subscription';

  @override
  String get settingsAppSection => 'App';

  @override
  String get settingsAccountSection => 'Account';

  @override
  String get settingsLegalSection => 'Legal';

  @override
  String get settingsSupportSection => 'Support';

  @override
  String get settingsNotificationsSubtitle => 'Manage feeding reminders';

  @override
  String get settingsAppearanceSubtitle => 'Theme and display options';

  @override
  String get settingsFamilySubtitle => 'Invite family members to help feed';

  @override
  String get settingsDeleteAccountSubtitle => 'Permanently delete your account';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle => 'How we handle your data';

  @override
  String get settingsTermsSubtitle => 'Usage terms and conditions';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get settingsLicensesSubtitle => 'Open source licenses';

  @override
  String get settingsContactSupport => 'Contact Support';

  @override
  String get settingsContactSupportSubtitle => 'Get help via email';

  @override
  String get settingsRateApp => 'Rate App';

  @override
  String get settingsRateAppSubtitle => 'Share your experience';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get deleteAccountMessage =>
      'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.';

  @override
  String get deleteAccountWillDelete => 'This will permanently delete:';

  @override
  String get deleteAccountDataAquariums => 'All your aquariums and fish data';

  @override
  String get deleteAccountDataHistory => 'Your feeding history and streaks';

  @override
  String get deleteAccountDataAccount =>
      'Your account and personal information';

  @override
  String get deleteAccountIrreversible => 'This action is irreversible.';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get couldNotOpenAppStore => 'Could not open app store';

  @override
  String get purchasesRestoredSuccess => 'Purchases restored successfully';

  @override
  String get failedToRestorePurchases => 'Failed to restore purchases';

  @override
  String get restorePurchasesSubtitle => 'Recover previous purchases';

  @override
  String get subscriptionTrialActive => 'Trial active';

  @override
  String subscriptionTrialEndsIn(int days) {
    return 'Trial ends in $days days';
  }

  @override
  String subscriptionRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String subscriptionExpiresOn(String date) {
    return 'Expires on $date';
  }

  @override
  String get subscriptionActive => 'Active subscription';

  @override
  String get subscriptionAdsRemoved => 'Ads removed';

  @override
  String get subscriptionFreePlan => 'Free plan';

  @override
  String get choosePhoto => 'Choose Photo';

  @override
  String get setYourNickname => 'Set your nickname';

  @override
  String get editNickname => 'Edit nickname';

  @override
  String get enterYourNickname => 'Enter your nickname';

  @override
  String get permissionDenied =>
      'Camera or gallery permission denied. Please enable it in settings.';

  @override
  String get failedToPickImage => 'Failed to pick image. Please try again.';

  @override
  String shareProfileText(String userName) {
    return 'Check out my FishFeed profile! I\'m $userName on FishFeed - the best aquarium management app.';
  }

  @override
  String get viewPremium => 'View Premium';

  @override
  String get anErrorOccurred => 'An error occurred';

  @override
  String get accountDeletionNotImplemented =>
      'Account deletion is not yet implemented';

  @override
  String syncNewEventsReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new events received from server',
      one: '1 new event received from server',
    );
    return '$_temp0';
  }

  @override
  String syncEventsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events deleted from server',
      one: '1 event deleted from server',
    );
    return '$_temp0';
  }

  @override
  String syncConflictsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conflicts require attention',
      one: '1 conflict requires attention',
    );
    return '$_temp0';
  }

  @override
  String get syncServerWins => 'Server version applied';

  @override
  String get syncLocalWins => 'Your version kept';

  @override
  String get aquariumName => 'Aquarium Name';

  @override
  String get aquariumNameHint => 'e.g., Living Room Tank';

  @override
  String get aquariumNameTooLong => 'Name must be 50 characters or less';

  @override
  String get aquariumNameDescription =>
      'Give your aquarium a name to easily identify it';

  @override
  String get createYourFirstAquarium => 'Create Your First Aquarium';

  @override
  String get addAnotherAquarium => 'Add Another Aquarium';

  @override
  String get waterType => 'Water Type';

  @override
  String get freshwater => 'Freshwater';

  @override
  String get saltwater => 'Saltwater';

  @override
  String aquariumsCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aquariums created',
      one: '1 aquarium created',
    );
    return '$_temp0';
  }

  @override
  String get aquariumSetupComplete => 'Aquarium Setup Complete!';

  @override
  String get addMoreAquariumQuestion =>
      'Would you like to add another aquarium?';

  @override
  String get previouslyCreated => 'Previously created';

  @override
  String totalAquariums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aquariums total',
      one: '1 aquarium total',
    );
    return '$_temp0';
  }

  @override
  String get justCreated => 'New';

  @override
  String fishCountWithSpecies(int fishCount, int speciesCount) {
    return '$fishCount fish ($speciesCount species)';
  }

  @override
  String get failedToCreateAquarium =>
      'Failed to create aquarium. Please try again.';

  @override
  String get enterAquariumName => 'Enter your aquarium name';

  @override
  String get createAquarium => 'Create Aquarium';

  @override
  String get finishSetup => 'Finish Setup';

  @override
  String get myDefaultAquarium => 'My Aquarium';

  @override
  String get addAquarium => 'Add Aquarium';

  @override
  String get aquariumCreated => 'Aquarium created!';

  @override
  String get migratingData => 'Migrating your data...';

  @override
  String aquariumSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You created $count aquariums',
      one: 'You created 1 aquarium',
    );
    return '$_temp0';
  }

  @override
  String get noFeedingsForAquarium => 'No feedings scheduled';

  @override
  String get selectAquarium => 'Select Aquarium';

  @override
  String get selectAquariumDescription =>
      'Choose which aquarium to add your fish to';

  @override
  String get newAquarium => 'New Aquarium';

  @override
  String get editAquarium => 'Edit Aquarium';

  @override
  String get editAquariumDetails => 'Edit aquarium settings';

  @override
  String fishInAquarium(int count) {
    return 'Fish ($count)';
  }

  @override
  String get deleteAquarium => 'Delete Aquarium';

  @override
  String deleteAquariumTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteAquariumConfirmation =>
      'This will remove all fish and feeding history. This action cannot be undone.';

  @override
  String get aquariumDeleted => 'Aquarium deleted';

  @override
  String get aquariumUpdated => 'Aquarium updated';

  @override
  String get failedToUpdateAquarium => 'Failed to update aquarium';

  @override
  String get failedToDeleteAquarium => 'Failed to delete aquarium';

  @override
  String get aquariumNotFound => 'Aquarium not found';

  @override
  String get aquariumNotFoundDescription =>
      'The aquarium you\'re looking for doesn\'t exist or has been deleted.';

  @override
  String get noFishInAquarium => 'No fish in this aquarium';

  @override
  String get addFishToAquarium => 'Add your first fish to get started';

  @override
  String feedingsTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feedings today',
      one: '1 feeding today',
      zero: 'No feedings today',
    );
    return '$_temp0';
  }

  @override
  String get markAsFedQuestion => 'Mark as fed?';

  @override
  String get yesFed => 'Yes, Fed';

  @override
  String fedAtTime(String time) {
    return 'Fed at $time';
  }

  @override
  String get pendingSync => 'Syncing...';

  @override
  String pendingFeedingAt(String time) {
    return 'Pending feeding at $time';
  }

  @override
  String get allFedToday => 'All fed';

  @override
  String nextFeedingAt(String time) {
    return 'Next at $time';
  }

  @override
  String get portionHintLabel => 'Portion';

  @override
  String get feedingDetails => 'Feeding Details';

  @override
  String get closeButton => 'Close';

  @override
  String feedingAlreadyDoneByMember(String name, String time) {
    return '$name already fed at $time';
  }

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name!';
  }

  @override
  String get paywallUnlockPremium => 'Unlock Premium';

  @override
  String get paywallSubtitle =>
      'Get the most out of FishFeed with premium features';

  @override
  String get paywallPremiumBenefits => 'Premium Benefits';

  @override
  String get paywallChooseYourPlan => 'Choose Your Plan';

  @override
  String get paywallAnnual => 'Annual';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallBestValue => 'Best Value';

  @override
  String get paywallMostFlexible => 'Most Flexible';

  @override
  String paywallSavePercent(int percent) {
    return 'Save $percent%';
  }

  @override
  String get paywallStartFreeTrial => 'Start 7-Day Free Trial';

  @override
  String get paywallTrialTerms =>
      'Free trial for 7 days, then auto-renews at the selected plan price. Cancel anytime in App Store settings.';

  @override
  String get paywallFailedToLoadProducts => 'Failed to load products';

  @override
  String get paywallPurchaseFailed => 'Purchase failed';

  @override
  String get paywallOr => 'or';

  @override
  String paywallPerMonth(String price) {
    return '$price/month';
  }

  @override
  String get paywallExtendedStatistics => 'Extended Statistics (6 months)';

  @override
  String get paywallFamilyMode => 'Family Mode (5+ users)';

  @override
  String get paywallMultipleAquariums => 'Multiple Aquariums';

  @override
  String get paywallUnlimitedAiScans => 'Unlimited AI Fish Scans';

  @override
  String get feedingAlreadyCompleted =>
      'This feeding has already been completed';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get imageUploadProgress => 'Uploading...';

  @override
  String get imageUploadError => 'Upload failed. Tap to retry.';

  @override
  String get imageDeleteConfirm => 'Remove this photo?';

  @override
  String get imageDeleteButton => 'Remove';

  @override
  String get imagePlaceholder => 'No image';

  @override
  String get imageRetryButton => 'Retry';

  @override
  String get aquarium => 'Aquarium';

  @override
  String get aquariumDetails => 'Aquarium Details';

  @override
  String get fishDetails => 'Fish Details';

  @override
  String get volume => 'Volume';

  @override
  String get brackish => 'Brackish';

  @override
  String get feedingSchedule => 'Feeding Schedule';

  @override
  String get notes => 'Notes';

  @override
  String get addNotes => 'Add notes about this fish...';

  @override
  String get species => 'Species';

  @override
  String get added => 'Added';

  @override
  String get deleteFishConfirm => 'Delete this fish?';

  @override
  String fishMovedTo(String aquariumName) {
    return 'Moved to $aquariumName';
  }

  @override
  String get view => 'View';

  @override
  String get deleteAquariumConfirm => 'Delete this aquarium?';

  @override
  String get markAsFedButton => 'Mark as Fed';

  @override
  String get deleteFishBody =>
      'This will remove the fish and deactivate all its feeding schedules. This action cannot be undone.';

  @override
  String get intervalDaily => 'Daily';

  @override
  String get intervalWeekly => 'Weekly';

  @override
  String intervalEveryNDays(int count) {
    return 'Every $count days';
  }

  @override
  String get editFishButton => 'Edit Fish';

  @override
  String get scheduledTime => 'Scheduled Time';

  @override
  String get foodTypeFlakes => 'Flakes';

  @override
  String get foodTypePellets => 'Pellets';

  @override
  String get foodTypeFrozen => 'Frozen';

  @override
  String get foodTypeLive => 'Live';

  @override
  String get foodTypeMixed => 'Mixed';

  @override
  String get feedingInterval => 'Feeding Interval';

  @override
  String get feedingTimes => 'Feeding Times';

  @override
  String get addFeedingTime => 'Add Time';

  @override
  String get portionHintPlaceholder => 'e.g. 2 pinches, 3 pellets';

  @override
  String get everyOtherDay => 'Every 2 Days';

  @override
  String get themeDescriptionSystem =>
      'Automatically matches your device settings';

  @override
  String get themeDescriptionLight => 'Always use light theme';

  @override
  String get themeDescriptionDark => 'Always use dark theme';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'German';

  @override
  String get languageEnglishNative => 'English';

  @override
  String get languageGermanNative => 'Deutsch';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationPreferencesSavedLocally =>
      'Notification preferences are saved locally and will be synced with your account when online.';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get receiveRemindersAndAlerts =>
      'Receive feeding reminders and alerts';

  @override
  String get allNotificationsDisabled => 'All notifications are disabled';

  @override
  String get notificationTypes => 'Notification Types';

  @override
  String get feedingReminders => 'Feeding Reminders';

  @override
  String get feedingRemindersSubtitle => 'Get notified when it\'s time to feed';

  @override
  String get streakAlerts => 'Streak Alerts';

  @override
  String get streakAlertsSubtitle => 'Warnings when your streak is at risk';

  @override
  String get weeklySummary => 'Weekly Summary';

  @override
  String get weeklySummarySubtitle => 'Weekly feeding activity overview';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get enableQuietHours => 'Enable Quiet Hours';

  @override
  String get muteNotificationsDuringHours =>
      'Mute notifications during specified hours';

  @override
  String get feedingTimeNotificationTitle => 'Feeding Time!';

  @override
  String feedingTimeNotificationBody(String speciesText) {
    return 'Time to feed your $speciesText';
  }

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get preview => 'Preview';

  @override
  String get processing => 'Processing...';

  @override
  String get usePhoto => 'Use Photo';

  @override
  String get preparingImage => 'Preparing image...';

  @override
  String get failedToProcessImage => 'Failed to process image';

  @override
  String get aiResult => 'AI Result';

  @override
  String get lowConfidenceWarning =>
      'Low confidence. Please verify or select manually.';

  @override
  String get careLevelBeginner => 'Beginner';

  @override
  String get careLevelIntermediate => 'Intermediate';

  @override
  String get careLevelAdvanced => 'Advanced';

  @override
  String get feedingFreqOnceDaily => 'Once daily';

  @override
  String get feedingFreqTwiceDaily => 'Twice daily';

  @override
  String get feedingFreqDaily => 'Daily';

  @override
  String get feedingFreqEveryOtherDay => 'Every other day';

  @override
  String get recommendations => 'Recommendations';
}
