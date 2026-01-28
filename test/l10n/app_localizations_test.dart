import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishfeed/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    testWidgets('can be retrieved from context', (WidgetTester tester) async {
      late AppLocalizations? localizations;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(localizations, isNotNull);
    });

    testWidgets('supports English locale', (WidgetTester tester) async {
      late AppLocalizations? localizations;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(localizations, isNotNull);
      expect(localizations!.appTitle, 'FishFeed');
      expect(localizations!.welcomeMessage, 'Welcome to FishFeed');
      expect(localizations!.loginButton, 'Log In');
      expect(localizations!.registerButton, 'Register');
      expect(localizations!.settings, 'Settings');
      expect(localizations!.profile, 'Profile');
      expect(localizations!.calendar, 'Calendar');
      expect(localizations!.home, 'Home');
    });

    testWidgets('supports German locale', (WidgetTester tester) async {
      late AppLocalizations? localizations;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(localizations, isNotNull);
      expect(localizations!.appTitle, 'FishFeed');
      expect(localizations!.welcomeMessage, 'Willkommen bei FishFeed');
      expect(localizations!.loginButton, 'Anmelden');
      expect(localizations!.registerButton, 'Registrieren');
      expect(localizations!.settings, 'Einstellungen');
      expect(localizations!.profile, 'Profil');
      expect(localizations!.calendar, 'Kalender');
      expect(localizations!.home, 'Startseite');
    });

    testWidgets('displays correct English text in widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                appBar: AppBar(title: Text(l10n.home)),
                body: Column(
                  children: [
                    Text(l10n.welcomeMessage),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text(l10n.loginButton),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Welcome to FishFeed'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('displays correct German text in widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                appBar: AppBar(title: Text(l10n.home)),
                body: Column(
                  children: [
                    Text(l10n.welcomeMessage),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text(l10n.loginButton),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Startseite'), findsOneWidget);
      expect(find.text('Willkommen bei FishFeed'), findsOneWidget);
      expect(find.text('Anmelden'), findsOneWidget);
    });

    test('supportedLocales contains EN and DE', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
      expect(AppLocalizations.supportedLocales, contains(const Locale('de')));
      expect(AppLocalizations.supportedLocales.length, 2);
    });

    test('localizationsDelegates contains required delegates', () {
      expect(AppLocalizations.localizationsDelegates.length, 4);
      expect(
        AppLocalizations.localizationsDelegates,
        contains(AppLocalizations.delegate),
      );
    });
  });

  group('AppLocalizations - all strings', () {
    testWidgets('English locale has all expected strings', (
      WidgetTester tester,
    ) async {
      late AppLocalizations? localizations;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(localizations!.email, 'Email');
      expect(localizations!.password, 'Password');
      expect(localizations!.logout, 'Log Out');
      expect(localizations!.cancel, 'Cancel');
      expect(localizations!.save, 'Save');
      expect(localizations!.delete, 'Delete');
      expect(localizations!.edit, 'Edit');
      expect(localizations!.loading, 'Loading...');
      expect(localizations!.error, 'Error');
      expect(localizations!.retry, 'Retry');
      expect(localizations!.language, 'Language');
      expect(localizations!.theme, 'Theme');
      expect(localizations!.darkMode, 'Dark Mode');
      expect(localizations!.lightMode, 'Light Mode');
      expect(localizations!.systemMode, 'System');
    });

    testWidgets('German locale has all expected strings', (
      WidgetTester tester,
    ) async {
      late AppLocalizations? localizations;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              localizations = AppLocalizations.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(localizations!.email, 'E-Mail');
      expect(localizations!.password, 'Passwort');
      expect(localizations!.logout, 'Abmelden');
      expect(localizations!.cancel, 'Abbrechen');
      expect(localizations!.save, 'Speichern');
      expect(localizations!.delete, 'Löschen');
      expect(localizations!.edit, 'Bearbeiten');
      expect(localizations!.loading, 'Laden...');
      expect(localizations!.error, 'Fehler');
      expect(localizations!.retry, 'Wiederholen');
      expect(localizations!.language, 'Sprache');
      expect(localizations!.theme, 'Design');
      expect(localizations!.darkMode, 'Dunkelmodus');
      expect(localizations!.lightMode, 'Hellmodus');
      expect(localizations!.systemMode, 'System');
    });
  });
}
