// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'FishFeed';

  @override
  String get welcomeMessage => 'Willkommen bei FishFeed';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get registerButton => 'Registrieren';

  @override
  String get settings => 'Einstellungen';

  @override
  String get profile => 'Profil';

  @override
  String get calendar => 'Kalender';

  @override
  String get home => 'Startseite';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get logout => 'Abmelden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get loading => 'Laden...';

  @override
  String get error => 'Fehler';

  @override
  String get retry => 'Wiederholen';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Design';

  @override
  String get darkMode => 'Dunkelmodus';

  @override
  String get lightMode => 'Hellmodus';

  @override
  String get systemMode => 'System';

  @override
  String get fieldRequired => 'Dieses Feld ist erforderlich';

  @override
  String get invalidEmailFormat => 'Ungültiges E-Mail-Format';

  @override
  String get invalidPasswordFormat =>
      'Passwort muss mindestens 8 Zeichen mit 1 Zahl und 1 Großbuchstaben haben';

  @override
  String get noAccount => 'Noch kein Konto?';

  @override
  String get orContinueWith => 'Oder fortfahren mit';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get createAccountButton => 'Konto erstellen';

  @override
  String get alreadyHaveAccount => 'Bereits ein Konto?';

  @override
  String get agreeToTermsPrefix => 'Ich stimme den ';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get tosCheckboxRequired =>
      'Sie müssen den Nutzungsbedingungen zustimmen';

  @override
  String get passwordWeak => 'Schwach';

  @override
  String get passwordMedium => 'Mittel';

  @override
  String get passwordStrong => 'Stark';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get errorNoConnection =>
      'Keine Internetverbindung. Bitte überprüfen Sie Ihr Netzwerk.';

  @override
  String get errorServer =>
      'Serverfehler. Bitte versuchen Sie es später erneut.';

  @override
  String get errorInvalidCredentials =>
      'Ungültige E-Mail oder Passwort. Bitte versuchen Sie es erneut.';

  @override
  String get errorValidation =>
      'Bitte überprüfen Sie Ihre Eingabe und versuchen Sie es erneut.';

  @override
  String get errorOAuth =>
      'Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get errorGoogleSignIn =>
      'Google-Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get errorAppleSignIn =>
      'Apple-Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get errorOperationCancelled => 'Vorgang wurde abgebrochen.';

  @override
  String get errorLocalStorage =>
      'Lokaler Speicherfehler. Bitte starten Sie die App neu.';

  @override
  String get errorUnexpected =>
      'Ein unerwarteter Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String get successLogin => 'Willkommen zurück!';

  @override
  String get successRegister => 'Konto erfolgreich erstellt!';

  @override
  String get successLogout => 'Sie wurden abgemeldet.';

  @override
  String get notificationPermissionTitle => 'Benachrichtigungen aktivieren';

  @override
  String get notificationPermissionDescription =>
      'Erhalten Sie rechtzeitige Erinnerungen, Ihre Fische zu füttern. Wir benachrichtigen Sie zu geplanten Fütterungszeiten, damit Sie keine Mahlzeit verpassen.';

  @override
  String get notificationPermissionEnable => 'Benachrichtigungen aktivieren';

  @override
  String get notificationPermissionLater => 'Später';

  @override
  String get notificationsBannerTitle => 'Benachrichtigungen deaktiviert';

  @override
  String get notificationsBannerDescription =>
      'Aktivieren Sie Benachrichtigungen, um Fütterungserinnerungen zu erhalten';

  @override
  String get notificationsBannerAction => 'Aktivieren';

  @override
  String get notificationsSettingsTitle => 'Benachrichtigungen';

  @override
  String get notificationsSettingsOpenSettings => 'Einstellungen öffnen';

  @override
  String get notificationsSettingsDisabledHint =>
      'Benachrichtigungen sind deaktiviert. Tippen Sie, um die Einstellungen zu öffnen und sie zu aktivieren.';

  @override
  String get freezeDayDialogTitle => 'Fütterung verpasst';

  @override
  String get freezeDayDialogDescription =>
      'Sie haben heute die Fütterung Ihrer Fische verpasst. Verwenden Sie einen Freeze-Tag, um Ihre Serie zu schützen!';

  @override
  String get freezeDayDialogNoFreezeDescription =>
      'Sie haben heute die Fütterung Ihrer Fische verpasst und haben keine Freeze-Tage mehr. Ihre Serie wird zurückgesetzt.';

  @override
  String freezeDayDialogStreakAtRisk(int count) {
    return '$count-Tage-Serie in Gefahr';
  }

  @override
  String freezeDayDialogUseFreeze(int count) {
    return 'Freeze-Tag verwenden ($count übrig)';
  }

  @override
  String get freezeDayDialogLoseStreak => 'Serie verlieren';

  @override
  String get freezeIndicatorTooltipNone =>
      'Keine Freeze-Tage mehr diesen Monat';

  @override
  String get freezeIndicatorTooltipOne => '1 Freeze-Tag verfügbar';

  @override
  String freezeIndicatorTooltipMany(int count) {
    return '$count Freeze-Tage verfügbar';
  }

  @override
  String get freezeWarningNotificationTitle => 'Serie in Gefahr!';

  @override
  String freezeWarningNotificationBody(int freezeCount, int streakCount) {
    return 'Sie haben $freezeCount Freeze-Tag(e) verfügbar, um Ihre $streakCount-Tage-Serie zu schützen!';
  }

  @override
  String get emptyStateTodayTitle => 'Keine Ereignisse heute';

  @override
  String get emptyStateTodayDescription =>
      'Alle Ihre Fische sind gefüttert! Genießen Sie den Tag.';

  @override
  String get emptyStateFishListTitle => 'Noch keine Fische';

  @override
  String get emptyStateFishListDescription =>
      'Fügen Sie Ihren ersten Fisch hinzu, um Fütterungspläne zu verfolgen.';

  @override
  String get emptyStateFishListAction => 'Fisch hinzufügen';

  @override
  String get emptyStateAchievementsTitle => 'Noch keine Erfolge';

  @override
  String get emptyStateAchievementsDescription =>
      'Füttern Sie Ihre Fische regelmäßig, um Erfolge freizuschalten!';

  @override
  String get emptyStateCalendarTitle => 'Keine Fütterungshistorie';

  @override
  String get emptyStateCalendarDescription =>
      'Beginnen Sie mit der Fütterungsverfolgung, um Ihre Historie hier zu sehen.';

  @override
  String get errorStateNetworkTitle => 'Keine Verbindung';

  @override
  String get errorStateNetworkDescription =>
      'Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get errorStateServerTitle => 'Etwas ist schiefgelaufen';

  @override
  String get errorStateServerDescription =>
      'Wir haben Verbindungsprobleme. Bitte versuchen Sie es später erneut.';

  @override
  String get errorStateTimeoutTitle => 'Server antwortet nicht';

  @override
  String get errorStateTimeoutDescription =>
      'Die Anfrage hat zu lange gedauert. Bitte versuchen Sie es erneut.';

  @override
  String get errorStateGenericTitle => 'Ups!';

  @override
  String get errorStateGenericDescription =>
      'Etwas ist schiefgelaufen. Bitte versuchen Sie es erneut.';

  @override
  String get errorStateTryAgain => 'Erneut versuchen';

  @override
  String get errorStateContactSupport => 'Support kontaktieren';

  @override
  String get offlineBannerTitle => 'Sie sind offline';

  @override
  String get offlineBannerDescription =>
      'Einige Funktionen sind möglicherweise nicht verfügbar';

  @override
  String get lowStorageTitle => 'Speicherplatz niedrig';

  @override
  String lowStorageDescription(int size) {
    return 'Ihr Gerät hat weniger als $size MB freien Speicher. Einige Funktionen funktionieren möglicherweise nicht richtig.';
  }

  @override
  String get lowStorageClearCache => 'Cache leeren';

  @override
  String get lowStorageDismiss => 'Verstanden';

  @override
  String get cacheCleared => 'Cache erfolgreich geleert';

  @override
  String fishCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fische',
      one: '1 Fisch',
      zero: 'Keine Fische',
    );
    return '$_temp0';
  }

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: '0 Tage',
    );
    return '$_temp0';
  }

  @override
  String achievementCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Erfolge',
      one: '1 Erfolg',
      zero: 'Keine Erfolge',
    );
    return '$_temp0';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage Serie',
      one: '1 Tag Serie',
      zero: '0 Tage Serie',
    );
    return '$_temp0';
  }

  @override
  String get syncStatusOffline => 'Offline';

  @override
  String get syncStatusSyncing => 'Synchronisierung...';

  @override
  String get syncStatusSynced => 'Synchronisiert';

  @override
  String get syncStatusError => 'Sync fehlgeschlagen';

  @override
  String get syncStatusJustNow => 'Gerade eben';

  @override
  String syncStatusMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Min.',
      one: 'vor 1 Min.',
    );
    return '$_temp0';
  }

  @override
  String syncStatusHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String syncStatusDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get syncCannotSyncOffline => 'Synchronisierung offline nicht möglich';

  @override
  String get conflictDialogTitle => 'Sync-Konflikt';

  @override
  String get conflictDialogDescription =>
      'Dieses Element wurde auf einem anderen Gerät geändert. Wählen Sie, welche Version behalten werden soll.';

  @override
  String get conflictDifferingFields => 'Geänderte Felder:';

  @override
  String get conflictLocalVersion => 'Ihre Version';

  @override
  String get conflictServerVersion => 'Server-Version';

  @override
  String get conflictKeepMyVersion => 'Meine behalten';

  @override
  String get conflictUseServerVersion => 'Server verwenden';

  @override
  String get conflictDeletionTitle => 'Löschkonflikt';

  @override
  String get conflictDeletionDescription =>
      'Dieses Element wurde auf einem anderen Gerät gelöscht, aber Sie haben lokale Änderungen vorgenommen. Wählen Sie, ob Sie es wiederherstellen oder löschen möchten.';

  @override
  String get conflictRestoreItem => 'Wiederherstellen';

  @override
  String get conflictDeleteItem => 'Löschen';

  @override
  String conflictDeletedOn(String date) {
    return 'Gelöscht am $date';
  }

  @override
  String get myAquarium => 'Mein Aquarium';

  @override
  String get manageFish => 'Verwalten';

  @override
  String get addFish => 'Fisch hinzufügen';

  @override
  String get editFish => 'Fisch bearbeiten';

  @override
  String get deleteFish => 'Löschen';

  @override
  String deleteFishTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get confirmDeleteFish =>
      'Dies entfernt den Fisch und seinen Fütterungsplan.';

  @override
  String get fishQuantity => 'Anzahl';

  @override
  String get customName => 'Eigener Name';

  @override
  String get customNameHint => 'Geben Sie Ihrem Fisch einen Namen';

  @override
  String get customNameOptional => 'Optional - leer lassen für Artnamen';

  @override
  String get emptyAquarium => 'Noch keine Fische';

  @override
  String get addFirstFish => 'Fügen Sie Ihren ersten Fisch hinzu';

  @override
  String get addFirstFishDescription =>
      'Fügen Sie Ihren ersten Fisch hinzu, um die Fütterung zu verfolgen';

  @override
  String fishAddedSuccessfully(String name) {
    return '$name erfolgreich hinzugefügt';
  }

  @override
  String get fishDeletedSuccessfully => 'Fisch gelöscht';

  @override
  String get fishUpdatedSuccessfully => 'Änderungen gespeichert';

  @override
  String moreCount(int count) {
    return '+$count weitere';
  }

  @override
  String get addFishTooltip => 'Fisch hinzufügen';

  @override
  String get editFishDetails => 'Fischdetails bearbeiten';

  @override
  String get fishNotFound => 'Fisch nicht gefunden';

  @override
  String get fishNotFoundDescription =>
      'Der Fisch, den Sie bearbeiten möchten, existiert nicht mehr.';

  @override
  String get goBack => 'Zurück';

  @override
  String get failedToSaveChanges =>
      'Speichern fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get scanWithAiCamera => 'Mit AI-Kamera scannen';

  @override
  String get takePhotoToIdentify =>
      'Foto machen, um Fischart zu identifizieren';

  @override
  String get selectFromList => 'Aus Liste auswählen';

  @override
  String get chooseFromSpeciesList => 'Aus verfügbaren Arten auswählen';

  @override
  String get statisticsTitle => 'Statistiken';

  @override
  String get feedingsLabel => 'Fütterungen';

  @override
  String get daysWithApp => 'Tage mit FishFeed';

  @override
  String get onTimeLabel => 'Pünktlich';

  @override
  String get levelLabel => 'Level';

  @override
  String get experienceLabel => 'Erfahrung';

  @override
  String get streakTitle => 'Serie';

  @override
  String get currentStreakLabel => 'Aktuelle Serie';

  @override
  String get bestStreakLabel => 'Beste';

  @override
  String get freezeLabel => 'Freeze';

  @override
  String get freezeDaysTitle => 'Freeze-Tage';

  @override
  String get freezeDaysDescription =>
      'Freeze-Tage schützen Ihre Serie, wenn Sie eine Fütterung verpassen.';

  @override
  String freezeDaysPerMonth(int count) {
    return 'Sie erhalten $count Freeze-Tage pro Monat';
  }

  @override
  String get freezeDaysAutoUsed =>
      'Freeze wird automatisch verwendet, wenn Sie einen Tag verpassen';

  @override
  String freezeDaysAvailable(int count) {
    return 'Verfügbare Freeze-Tage: $count';
  }

  @override
  String get gotItButton => 'Verstanden';

  @override
  String milestoneDays(int count) {
    return '$count Tage';
  }

  @override
  String streakDaysInRow(int count) {
    return '$count Tage hintereinander!';
  }

  @override
  String get continueButton => 'Weiter';

  @override
  String get achievementsTitle => 'Erfolge';

  @override
  String get achievementFailedToLoad => 'Erfolge konnten nicht geladen werden';

  @override
  String get achievementCompleteToUnlock =>
      'Schließen Sie die Herausforderung ab, um freizuschalten';

  @override
  String get progressLabel => 'Fortschritt';

  @override
  String get shareButton => 'Teilen';

  @override
  String get sharingButton => 'Teilen...';

  @override
  String get achievementUnlocked => 'Erfolg freigeschaltet!';

  @override
  String get tapToClose => 'Tippen zum Schließen';

  @override
  String achievementProgress(int percent) {
    return 'Fortschritt: $percent%';
  }

  @override
  String get notUnlockedYet => 'Noch nicht freigeschaltet';

  @override
  String get locked => 'Gesperrt';

  @override
  String get achievementProgressTitle => 'Erfolgsfortschritt';

  @override
  String unlockedOn(String date) {
    return 'Freigeschaltet am $date';
  }

  @override
  String get feedingLabel => 'Fütterung';

  @override
  String get feedingCompleted => 'Fütterung abgeschlossen!';

  @override
  String get feedingMissed => 'Verpasst';

  @override
  String get statusGreatJob => 'Gut gemacht!';

  @override
  String get statusNextTime => 'Nächstes Mal klappt es!';

  @override
  String get statusPendingFeeding => 'Ausstehende Fütterung';

  @override
  String get levelBeginner => 'Anfänger';

  @override
  String get levelCaretaker => 'Pfleger';

  @override
  String get levelMaster => 'Meister';

  @override
  String get levelPro => 'Profi';

  @override
  String get levelBeginnerTooltip =>
      'Anfänger-Aquarianer - erste Schritte in der Fischpflege';

  @override
  String get levelCaretakerTooltip =>
      'Pfleger - kümmern sich regelmäßig um Ihre Fische';

  @override
  String get levelMasterTooltip => 'Meister - erfahrener Aquarianer';

  @override
  String get levelProTooltip => 'Profi - Experte in der Fischpflege!';

  @override
  String get maxLevel => 'Max. Level';

  @override
  String get familyAccess => 'Familienzugang';

  @override
  String get familyMode => 'Familienmodus';

  @override
  String get familyModeDescription =>
      'Laden Sie Familienmitglieder ein, gemeinsam für Ihre Fische zu sorgen. Jeder kann füttern und sehen, wer gefüttert hat.';

  @override
  String get activeInvitations => 'Aktive Einladungen';

  @override
  String get familyMembers => 'Familienmitglieder';

  @override
  String membersCount(int current, int max) {
    return 'Mitglieder: $current / $max';
  }

  @override
  String get limitReached => 'Limit erreicht';

  @override
  String get freePlanLimitReached => 'Kostenlos-Plan-Limit erreicht';

  @override
  String upgradeToPremiumFamily(int count) {
    return 'Upgrade auf Premium, um bis zu $count Familienmitglieder hinzuzufügen und auf Fütterungsstatistiken zuzugreifen.';
  }

  @override
  String upToMembers(int count) {
    return 'Bis zu $count Mitglieder';
  }

  @override
  String get statisticsFeature => 'Statistiken';

  @override
  String get managementFeature => 'Verwaltung';

  @override
  String get goToPremium => 'Zu Premium';

  @override
  String get inviteFamilyMember => 'Familienmitglied einladen';

  @override
  String get youAreOnlyMember => 'Sie sind das einzige Familienmitglied';

  @override
  String get inviteSomeone =>
      'Laden Sie jemanden ein, gemeinsam das Aquarium zu pflegen';

  @override
  String joinMyAquarium(String link, String code) {
    return 'Tritt meinem Aquarium in FishFeed bei!\n\nFolge dem Link: $link\n\nOder gib den Code ein: $code';
  }

  @override
  String get invitationToFishFeed => 'Einladung zu FishFeed';

  @override
  String get linkCopied => 'Link kopiert';

  @override
  String get cancelInvitation => 'Einladung stornieren?';

  @override
  String get cancelInvitationDescription =>
      'Diese Einladung kann nicht mehr verwendet werden.';

  @override
  String get no => 'Nein';

  @override
  String get removeMember => 'Mitglied entfernen?';

  @override
  String removeMemberDescription(String name) {
    return 'Sind Sie sicher, dass Sie $name entfernen möchten?';
  }

  @override
  String get remove => 'Entfernen';

  @override
  String get invitationCreated => 'Einladung erstellt!';

  @override
  String validForHours(int hours) {
    return 'Gültig für $hours Stunden';
  }

  @override
  String get invitationCode => 'Einladungscode';

  @override
  String get copy => 'Kopieren';

  @override
  String get share => 'Teilen';

  @override
  String validForHoursShort(int hours) {
    return 'Gültig für ${hours}h';
  }

  @override
  String validForMinutesShort(int minutes) {
    return 'Gültig für ${minutes}m';
  }

  @override
  String get expiring => 'Läuft ab';

  @override
  String get user => 'Benutzer';

  @override
  String get owner => 'Besitzer';

  @override
  String get member => 'Mitglied';

  @override
  String joinedDate(String date) {
    return 'Beigetreten: $date';
  }

  @override
  String feedingsThisWeek(int count) {
    return '$count diese Woche';
  }

  @override
  String feedingsThisMonth(int count) {
    return '$count diesen Monat';
  }

  @override
  String get errorOccurred => 'Ein Fehler ist aufgetreten';

  @override
  String get joiningFamily => 'Familie beitreten...';

  @override
  String get processingInvitation =>
      'Bitte warten Sie, während wir Ihre Einladung verarbeiten';

  @override
  String get congratulations => 'Herzlichen Glückwunsch!';

  @override
  String get joinedFamilySuccess =>
      'Sie sind dem Familienaquarium erfolgreich beigetreten';

  @override
  String get redirecting => 'Weiterleitung...';

  @override
  String get loginRequired => 'Anmeldung erforderlich';

  @override
  String get invitationError => 'Einladungsfehler';

  @override
  String get loginToAcceptInvitation =>
      'Melden Sie sich an, um die Einladung anzunehmen';

  @override
  String get logIn => 'Anmelden';

  @override
  String get toHome => 'Zur Startseite';

  @override
  String feedingCompletedByUser(String userName) {
    return 'Fütterung abgeschlossen: $userName';
  }

  @override
  String get familyMember => 'Familienmitglied';

  @override
  String get feedingDone => 'Fütterung erledigt';

  @override
  String get feedingTime => 'Fütterungszeit!';

  @override
  String timeToFeed(String fishName) {
    return 'Zeit, $fishName zu füttern';
  }

  @override
  String get yourFish => 'Ihre Fische';

  @override
  String get eventOverdue => 'Ereignis überfällig';

  @override
  String eventOverdueFor(String fishName) {
    return 'Ereignis überfällig für $fishName';
  }

  @override
  String get confirmStatus => 'Status bestätigen';

  @override
  String get confirmFeedingStatus => 'Fütterungsstatus bestätigen';

  @override
  String get fedAction => 'Gefüttert ✓';

  @override
  String get snoozeAction => '15 Min. später';

  @override
  String shareAchievementGeneric(String title) {
    return 'Ich habe den Erfolg \"$title\" in FishFeed erhalten! 🐟🏆';
  }

  @override
  String get shareFirstFeeding =>
      'Ich habe angefangen, mich um Fische in FishFeed zu kümmern! 🐟 Erste Fütterung erledigt! 🎉';

  @override
  String get shareStreak7 =>
      'Eine Woche ohne Auslassen! 🔥 Meine Serie in FishFeed: 7 Tage! 🏆';

  @override
  String get shareStreak30 =>
      'Ein Monat Perfektion! 🌟 30 Tage Fütterungen in Folge in FishFeed! 🔥';

  @override
  String get shareStreak100 =>
      'Legendäre Serie! 💎 100 Tage Fütterungen ohne Auslassen in FishFeed! 🏆🔥';

  @override
  String get sharePerfectWeek =>
      'Perfekte Woche! ✨ Keine verpassten Fütterungen in FishFeed! 🐟';

  @override
  String get shareFeedings50 =>
      'Engagierter Pfleger! 🐠 50 Fütterungen in FishFeed abgeschlossen! 🎉';

  @override
  String get shareFeedings100 =>
      'Hundert Fütterungen! 🎯 100 Mal meine Fische in FishFeed gefüttert! 🐟';

  @override
  String get shareFeedings500 =>
      'Fütterungsmeister! 👑 500 Fütterungen in FishFeed! Meine Fische sind in guten Händen! 🐟🏆';

  @override
  String get shareFeedings1000 =>
      'Fischflüsterer! 🌊 1000 Fütterungen in FishFeed! Wahre Hingabe! 🐟💎';

  @override
  String shareStreakLong(String appName, int days) {
    return 'Unglaublich! 💎 Meine Serie in $appName: $days Tage! 🔥🏆';
  }

  @override
  String shareStreakMedium(String appName, int days) {
    return 'Erstaunlich! 🌟 Meine Serie in $appName: $days Tage! 🔥';
  }

  @override
  String shareStreakShort(String appName, int days) {
    return 'Toll! 🔥 Meine Serie in $appName: $days Tage!';
  }

  @override
  String shareStreakDefault(String appName, int days) {
    return 'Meine Serie in $appName: $days Tage! 🐟';
  }

  @override
  String get achievementUnlockedCard => 'ERFOLG FREIGESCHALTET';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get monday => 'Montag';

  @override
  String get tuesday => 'Dienstag';

  @override
  String get wednesday => 'Mittwoch';

  @override
  String get thursday => 'Donnerstag';

  @override
  String get friday => 'Freitag';

  @override
  String get saturday => 'Samstag';

  @override
  String get sunday => 'Sonntag';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mär';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dez';

  @override
  String get noFeedingsScheduled => 'Keine Fütterungen geplant';

  @override
  String feedingsCompleted(int completed, int total) {
    return '$completed von $total Fütterungen abgeschlossen';
  }

  @override
  String get statusComplete => 'Vollständig';

  @override
  String get statusMissed => 'Verpasst';

  @override
  String get statusPartial => 'Teilweise';

  @override
  String get statusNoData => 'Keine Daten';

  @override
  String get loadingFeedings => 'Lade Fütterungen...';

  @override
  String get allFeedingsCompleted => 'Alle Fütterungen abgeschlossen';

  @override
  String get allFeedingsMissed => 'Alle Fütterungen verpasst';

  @override
  String get someFeedingsCompleted => 'Einige Fütterungen abgeschlossen';

  @override
  String get noFeedingData => 'Keine Fütterungsdaten';

  @override
  String get logoutConfirmTitle => 'Abmelden';

  @override
  String get logoutConfirmMessage => 'Möchten Sie sich wirklich abmelden?';

  @override
  String get deleteAccountTitle => 'Konto löschen';

  @override
  String get deleteAccountConfirm => 'Endgültige Bestätigung';

  @override
  String get deleteMyAccount => 'Mein Konto löschen';

  @override
  String get subscription => 'Abonnement';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get recoverPreviousPurchases => 'Frühere Käufe wiederherstellen';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get chooseFromGallery => 'Aus Galerie wählen';

  @override
  String get nickname => 'Spitzname';

  @override
  String get nicknameUpdated => 'Spitzname erfolgreich aktualisiert';

  @override
  String get failedToShareProfile => 'Profil konnte nicht geteilt werden';

  @override
  String get shareProfile => 'Profil teilen';

  @override
  String get premiumFeature => 'Premium-Funktion';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get upgradeToPremium => 'Auf Premium upgraden';

  @override
  String get unlockAllFeatures => 'Alle Funktionen freischalten';

  @override
  String upgradeToUnlock(String feature) {
    return 'Upgrade, um $feature freizuschalten';
  }

  @override
  String get noAds => 'Keine Werbung';

  @override
  String get unlimitedAiScans => 'Unbegrenzte AI-Scans';

  @override
  String get sixMonthsHistory => '6 Monate Historie';

  @override
  String get viewPlans => 'Pläne ansehen';

  @override
  String get trial => 'Testversion';

  @override
  String get premium => 'Premium';

  @override
  String get free => 'Kostenlos';

  @override
  String get goPremium => 'Zu Premium';

  @override
  String get addManually => 'Manuell hinzufügen';

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String get removeAds => 'Werbung entfernen';

  @override
  String get oneTimePurchase => 'Einmaliger Kauf';

  @override
  String get tryPremiumFeatures =>
      'Alle Premium-Funktionen testen. Jederzeit kündbar.';

  @override
  String get upgradePremiumAiScans =>
      'Upgrade auf Premium für unbegrenzte AI-Fischerkennung';

  @override
  String get priorityProcessing => 'Prioritätsverarbeitung';

  @override
  String get higherAccuracy => 'Höhere Genauigkeit';

  @override
  String get analyzing => 'Analysiere...';

  @override
  String get retake => 'Neu aufnehmen';

  @override
  String get selectManually => 'Manuell auswählen';

  @override
  String get confirmAnyway => 'Trotzdem bestätigen';

  @override
  String get notCorrect => 'Nicht korrekt?';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get noScansLeft => 'Keine Scans mehr';

  @override
  String get back => 'Zurück';

  @override
  String get foodType => 'Futterart';

  @override
  String get portion => 'Portion';

  @override
  String get from => 'Von';

  @override
  String get to => 'Bis';

  @override
  String get continueWithGoogle => 'Mit Google fortfahren';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get appearance => 'Darstellung';

  @override
  String get welcomeToPremium => 'Willkommen bei Premium!';

  @override
  String get adsRemovedSuccessfully => 'Werbung erfolgreich entfernt!';

  @override
  String get noPreviousPurchases => 'Keine früheren Käufe gefunden';

  @override
  String get premiumComingSoon => 'Premium-Abonnement kommt bald!';

  @override
  String get comingSoon => 'Demnächst verfügbar';

  @override
  String get aiCameraComingSoonMessage =>
      'KI-Fischerkennung kommt bald! Bleiben Sie dran für Updates.';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get thisMonth => 'Diesen Monat';

  @override
  String get sixMonths => '6 Monate';

  @override
  String get achievementFirstFeeding => 'Erste Fütterung';

  @override
  String get achievementFirstFeedingDesc =>
      'Schließen Sie Ihre erste Fütterung ab';

  @override
  String get achievementStreak7 => 'Wöchentliche Serie';

  @override
  String get achievementStreak7Desc => '7 aufeinanderfolgende Fütterungstage';

  @override
  String get achievementStreak30 => 'Monatliche Serie';

  @override
  String get achievementStreak30Desc => '30 aufeinanderfolgende Fütterungstage';

  @override
  String get achievementStreak100 => 'Legendäre Serie';

  @override
  String get achievementStreak100Desc =>
      '100 aufeinanderfolgende Fütterungstage';

  @override
  String get achievementPerfectWeek => 'Perfekte Woche';

  @override
  String get achievementPerfectWeekDesc =>
      'Keine verpassten Fütterungen für eine ganze Woche';

  @override
  String get achievementFeedings100 => 'Jahrhundert-Fütterer';

  @override
  String get achievementFeedings100Desc =>
      '100 Fütterungen insgesamt abschließen';

  @override
  String get achievementFeedings50 => 'Engagierter Pfleger';

  @override
  String get achievementFeedings50Desc =>
      '50 Fütterungen insgesamt abschließen';

  @override
  String get achievementFeedings500 => 'Fütterungsmeister';

  @override
  String get achievementFeedings500Desc =>
      '500 Fütterungen insgesamt abschließen';

  @override
  String get achievementFeedings1000 => 'Fischflüsterer';

  @override
  String get achievementFeedings1000Desc =>
      '1000 Fütterungen insgesamt abschließen';

  @override
  String get achievementLocked => 'Gesperrt';

  @override
  String get achievementNotYetUnlocked => 'Noch nicht freigeschaltet';

  @override
  String achievementUnlockedOn(String date) {
    return 'Freigeschaltet am $date';
  }

  @override
  String get tapToDismiss => 'Tippen zum Schließen';

  @override
  String get settingsSubscriptionSection => 'Abonnement';

  @override
  String get settingsAppSection => 'App';

  @override
  String get settingsAccountSection => 'Konto';

  @override
  String get settingsLegalSection => 'Rechtliches';

  @override
  String get settingsSupportSection => 'Hilfe';

  @override
  String get settingsNotificationsSubtitle =>
      'Fütterungserinnerungen verwalten';

  @override
  String get settingsAppearanceSubtitle => 'Design und Anzeigeoptionen';

  @override
  String get settingsFamilySubtitle => 'Familienmitglieder zum Helfen einladen';

  @override
  String get settingsDeleteAccountSubtitle => 'Konto dauerhaft löschen';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get settingsPrivacyPolicySubtitle => 'Wie wir Ihre Daten behandeln';

  @override
  String get settingsTermsSubtitle => 'Nutzungsbedingungen';

  @override
  String get settingsLicenses => 'Lizenzen';

  @override
  String get settingsLicensesSubtitle => 'Open-Source-Lizenzen';

  @override
  String get settingsContactSupport => 'Support kontaktieren';

  @override
  String get settingsContactSupportSubtitle => 'Hilfe per E-Mail erhalten';

  @override
  String get settingsRateApp => 'App bewerten';

  @override
  String get settingsRateAppSubtitle => 'Teilen Sie Ihre Erfahrung';

  @override
  String get settingsAppVersion => 'App-Version';

  @override
  String get deleteAccountMessage =>
      'Möchten Sie Ihr Konto wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden und alle Ihre Daten werden dauerhaft gelöscht.';

  @override
  String get deleteAccountWillDelete => 'Folgendes wird dauerhaft gelöscht:';

  @override
  String get deleteAccountDataAquariums => 'Alle Ihre Aquarien und Fischdaten';

  @override
  String get deleteAccountDataHistory => 'Ihre Fütterungshistorie und Serien';

  @override
  String get deleteAccountDataAccount =>
      'Ihr Konto und persönliche Informationen';

  @override
  String get deleteAccountIrreversible => 'Diese Aktion ist unwiderruflich.';

  @override
  String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get couldNotOpenAppStore => 'App Store konnte nicht geöffnet werden';

  @override
  String get purchasesRestoredSuccess => 'Käufe erfolgreich wiederhergestellt';

  @override
  String get failedToRestorePurchases =>
      'Käufe konnten nicht wiederhergestellt werden';

  @override
  String get restorePurchasesSubtitle => 'Frühere Käufe wiederherstellen';

  @override
  String get subscriptionTrialActive => 'Testversion aktiv';

  @override
  String subscriptionTrialEndsIn(int days) {
    return 'Testversion endet in $days Tagen';
  }

  @override
  String subscriptionRenewsOn(String date) {
    return 'Verlängert sich am $date';
  }

  @override
  String subscriptionExpiresOn(String date) {
    return 'Läuft ab am $date';
  }

  @override
  String get subscriptionActive => 'Aktives Abonnement';

  @override
  String get subscriptionAdsRemoved => 'Werbung entfernt';

  @override
  String get subscriptionFreePlan => 'Kostenloser Plan';

  @override
  String get choosePhoto => 'Foto auswählen';

  @override
  String get setYourNickname => 'Spitznamen festlegen';

  @override
  String get editNickname => 'Spitznamen bearbeiten';

  @override
  String get enterYourNickname => 'Geben Sie Ihren Spitznamen ein';

  @override
  String get permissionDenied =>
      'Kamera- oder Galerieberechtigung verweigert. Bitte in den Einstellungen aktivieren.';

  @override
  String get failedToPickImage =>
      'Bild konnte nicht ausgewählt werden. Bitte erneut versuchen.';

  @override
  String shareProfileText(String userName) {
    return 'Schaut euch mein FishFeed-Profil an! Ich bin $userName auf FishFeed - der besten Aquarium-Management-App.';
  }

  @override
  String get viewPremium => 'Premium anzeigen';

  @override
  String get anErrorOccurred => 'Ein Fehler ist aufgetreten';

  @override
  String get accountDeletionNotImplemented =>
      'Kontolöschung ist noch nicht implementiert';

  @override
  String syncNewEventsReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Ereignisse vom Server empfangen',
      one: '1 neues Ereignis vom Server empfangen',
    );
    return '$_temp0';
  }

  @override
  String syncEventsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ereignisse vom Server gelöscht',
      one: '1 Ereignis vom Server gelöscht',
    );
    return '$_temp0';
  }

  @override
  String syncConflictsDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Konflikte erfordern Aufmerksamkeit',
      one: '1 Konflikt erfordert Aufmerksamkeit',
    );
    return '$_temp0';
  }

  @override
  String get syncServerWins => 'Server-Version angewendet';

  @override
  String get syncLocalWins => 'Ihre Version behalten';

  @override
  String get aquariumName => 'Aquariumname';

  @override
  String get aquariumNameHint => 'z.B. Wohnzimmer-Aquarium';

  @override
  String get aquariumNameTooLong => 'Name darf maximal 50 Zeichen lang sein';

  @override
  String get aquariumNameDescription =>
      'Geben Sie Ihrem Aquarium einen Namen zur einfachen Identifizierung';

  @override
  String get createYourFirstAquarium => 'Erstellen Sie Ihr erstes Aquarium';

  @override
  String get addAnotherAquarium => 'Weiteres Aquarium hinzufügen';

  @override
  String get waterType => 'Wasserart';

  @override
  String get freshwater => 'Süßwasser';

  @override
  String get saltwater => 'Salzwasser';

  @override
  String aquariumsCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aquarien erstellt',
      one: '1 Aquarium erstellt',
    );
    return '$_temp0';
  }

  @override
  String get aquariumSetupComplete => 'Aquarium-Einrichtung abgeschlossen!';

  @override
  String get addMoreAquariumQuestion =>
      'Möchten Sie ein weiteres Aquarium hinzufügen?';

  @override
  String get previouslyCreated => 'Zuvor erstellt';

  @override
  String totalAquariums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aquarien insgesamt',
      one: '1 Aquarium insgesamt',
    );
    return '$_temp0';
  }

  @override
  String get justCreated => 'Neu';

  @override
  String fishCountWithSpecies(int fishCount, int speciesCount) {
    return '$fishCount Fische ($speciesCount Arten)';
  }

  @override
  String get failedToCreateAquarium =>
      'Aquarium konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get enterAquariumName => 'Geben Sie den Namen Ihres Aquariums ein';

  @override
  String get createAquarium => 'Aquarium erstellen';

  @override
  String get finishSetup => 'Einrichtung abschließen';

  @override
  String get myDefaultAquarium => 'Mein Aquarium';

  @override
  String get addAquarium => 'Aquarium hinzufügen';

  @override
  String get aquariumCreated => 'Aquarium erstellt!';

  @override
  String get migratingData => 'Ihre Daten werden migriert...';

  @override
  String aquariumSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sie haben $count Aquarien erstellt',
      one: 'Sie haben 1 Aquarium erstellt',
    );
    return '$_temp0';
  }

  @override
  String get noFeedingsForAquarium => 'Keine Fütterungen geplant';

  @override
  String get selectAquarium => 'Aquarium auswählen';

  @override
  String get selectAquariumDescription =>
      'Wählen Sie das Aquarium für Ihren Fisch';

  @override
  String get newAquarium => 'Neues Aquarium';

  @override
  String get editAquarium => 'Aquarium bearbeiten';

  @override
  String get editAquariumDetails => 'Aquarium-Einstellungen bearbeiten';

  @override
  String fishInAquarium(int count) {
    return 'Fische ($count)';
  }

  @override
  String get deleteAquarium => 'Aquarium löschen';

  @override
  String deleteAquariumTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get deleteAquariumConfirmation =>
      'Alle Fische und die Fütterungshistorie werden entfernt. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get aquariumDeleted => 'Aquarium gelöscht';

  @override
  String get aquariumUpdated => 'Aquarium aktualisiert';

  @override
  String get failedToUpdateAquarium =>
      'Aquarium konnte nicht aktualisiert werden';

  @override
  String get failedToDeleteAquarium => 'Aquarium konnte nicht gelöscht werden';

  @override
  String get aquariumNotFound => 'Aquarium nicht gefunden';

  @override
  String get aquariumNotFoundDescription =>
      'Das gesuchte Aquarium existiert nicht oder wurde gelöscht.';

  @override
  String get noFishInAquarium => 'Keine Fische in diesem Aquarium';

  @override
  String get addFishToAquarium =>
      'Fügen Sie Ihren ersten Fisch hinzu, um zu beginnen';

  @override
  String feedingsTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fütterungen heute',
      one: '1 Fütterung heute',
      zero: 'Keine Fütterungen heute',
    );
    return '$_temp0';
  }

  @override
  String get markAsFedQuestion => 'Als gefüttert markieren?';

  @override
  String get yesFed => 'Ja, gefüttert';

  @override
  String fedAtTime(String time) {
    return 'Gefüttert um $time';
  }

  @override
  String get pendingSync => 'Synchronisieren...';

  @override
  String pendingFeedingAt(String time) {
    return 'Ausstehende Fütterung um $time';
  }

  @override
  String get allFedToday => 'Alle gefüttert';

  @override
  String nextFeedingAt(String time) {
    return 'Nächste um $time';
  }

  @override
  String get portionHintLabel => 'Portion';

  @override
  String get feedingDetails => 'Fütterungsdetails';

  @override
  String get closeButton => 'Schließen';

  @override
  String feedingAlreadyDoneByMember(String name, String time) {
    return '$name hat bereits um $time gefüttert';
  }

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String greetingWithName(String greeting, String name) {
    return '$greeting, $name!';
  }

  @override
  String get paywallUnlockPremium => 'Premium freischalten';

  @override
  String get paywallSubtitle =>
      'Hole das Beste aus FishFeed mit Premium-Funktionen';

  @override
  String get paywallPremiumBenefits => 'Premium-Vorteile';

  @override
  String get paywallChooseYourPlan => 'Wähle deinen Plan';

  @override
  String get paywallAnnual => 'Jährlich';

  @override
  String get paywallMonthly => 'Monatlich';

  @override
  String get paywallBestValue => 'Bester Wert';

  @override
  String get paywallMostFlexible => 'Am flexibelsten';

  @override
  String paywallSavePercent(int percent) {
    return '$percent% sparen';
  }

  @override
  String get paywallStartFreeTrial => '7-Tage-Testversion starten';

  @override
  String get paywallTrialTerms =>
      'Kostenlose Testversion für 7 Tage, dann automatische Verlängerung zum gewählten Planpreis. Jederzeit in den App-Store-Einstellungen kündbar.';

  @override
  String get paywallFailedToLoadProducts =>
      'Produkte konnten nicht geladen werden';

  @override
  String get paywallPurchaseFailed => 'Kauf fehlgeschlagen';

  @override
  String get paywallOr => 'oder';

  @override
  String paywallPerMonth(String price) {
    return '$price/Monat';
  }

  @override
  String get paywallExtendedStatistics => 'Erweiterte Statistiken (6 Monate)';

  @override
  String get paywallFamilyMode => 'Familienmodus (5+ Benutzer)';

  @override
  String get paywallMultipleAquariums => 'Mehrere Aquarien';

  @override
  String get paywallUnlimitedAiScans => 'Unbegrenzte KI-Fischscans';

  @override
  String get feedingAlreadyCompleted =>
      'Diese Fütterung wurde bereits abgeschlossen';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get imageUploadProgress => 'Wird hochgeladen...';

  @override
  String get imageUploadError =>
      'Upload fehlgeschlagen. Tippen zum Wiederholen.';

  @override
  String get imageDeleteConfirm => 'Dieses Foto entfernen?';

  @override
  String get imageDeleteButton => 'Entfernen';

  @override
  String get imagePlaceholder => 'Kein Bild';

  @override
  String get imageRetryButton => 'Erneut versuchen';

  @override
  String get aquarium => 'Aquarium';

  @override
  String get aquariumDetails => 'Aquariumdetails';

  @override
  String get fishDetails => 'Fischdetails';

  @override
  String get volume => 'Volumen';

  @override
  String get brackish => 'Brackwasser';

  @override
  String get feedingSchedule => 'Fütterungsplan';

  @override
  String get notes => 'Notizen';

  @override
  String get addNotes => 'Notizen zu diesem Fisch hinzufügen...';

  @override
  String get species => 'Art';

  @override
  String get added => 'Hinzugefügt';

  @override
  String get deleteFishConfirm => 'Diesen Fisch löschen?';

  @override
  String fishMovedTo(String aquariumName) {
    return 'Verschoben nach $aquariumName';
  }

  @override
  String get view => 'Anzeigen';

  @override
  String get deleteAquariumConfirm => 'Dieses Aquarium löschen?';

  @override
  String get markAsFedButton => 'Als gefüttert markieren';

  @override
  String get deleteFishBody =>
      'Dadurch wird der Fisch entfernt und alle zugehörigen Fütterungspläne deaktiviert. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get intervalDaily => 'Täglich';

  @override
  String get intervalWeekly => 'Wöchentlich';

  @override
  String intervalEveryNDays(int count) {
    return 'Alle $count Tage';
  }

  @override
  String get editFishButton => 'Fisch bearbeiten';

  @override
  String get scheduledTime => 'Geplante Zeit';

  @override
  String get foodTypeFlakes => 'Flocken';

  @override
  String get foodTypePellets => 'Pellets';

  @override
  String get foodTypeFrozen => 'Tiefgekühlt';

  @override
  String get foodTypeLive => 'Lebendfutter';

  @override
  String get foodTypeMixed => 'Gemischt';

  @override
  String get feedingInterval => 'Fütterungsintervall';

  @override
  String get feedingTimes => 'Fütterungszeiten';

  @override
  String get addFeedingTime => 'Zeit hinzufügen';

  @override
  String get portionHintPlaceholder => 'z.B. 2 Prisen, 3 Pellets';

  @override
  String get everyOtherDay => 'Alle 2 Tage';
}
