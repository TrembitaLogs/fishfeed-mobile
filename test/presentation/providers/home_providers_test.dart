import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/presentation/providers/home_providers.dart';

void main() {
  group('greetingProvider', () {
    test('returns GreetingData with greeting, timePeriod, and emoji', () {
      final container = ProviderContainer();

      final greeting = container.read(greetingProvider);

      expect(greeting.greeting, isNotEmpty);
      expect(greeting.emoji, isNotEmpty);
      expect(greeting.timePeriod, isNotNull);

      container.dispose();
    });

    test('greeting message matches time period', () {
      final container = ProviderContainer();

      final greeting = container.read(greetingProvider);
      final hour = DateTime.now().hour;

      if (hour >= 6 && hour < 12) {
        expect(greeting.greeting, equals('Good morning'));
        expect(greeting.timePeriod, equals(TimePeriod.morning));
      } else if (hour >= 12 && hour < 18) {
        expect(greeting.greeting, equals('Good afternoon'));
        expect(greeting.timePeriod, equals(TimePeriod.afternoon));
      } else if (hour >= 18 && hour < 22) {
        expect(greeting.greeting, equals('Good evening'));
        expect(greeting.timePeriod, equals(TimePeriod.evening));
      } else {
        expect(greeting.greeting, equals('Good night'));
        expect(greeting.timePeriod, equals(TimePeriod.night));
      }

      container.dispose();
    });
  });

  group('greetingMessageProvider', () {
    test('returns only the greeting string', () {
      final container = ProviderContainer();

      final message = container.read(greetingMessageProvider);

      expect(message, isA<String>());
      expect(
        message,
        anyOf(
          equals('Good morning'),
          equals('Good afternoon'),
          equals('Good evening'),
          equals('Good night'),
        ),
      );

      container.dispose();
    });
  });

  group('personalizedGreetingProvider', () {
    test('returns greeting with name when provided', () {
      final container = ProviderContainer();

      final greeting = container.read(personalizedGreetingProvider('John'));

      expect(greeting, contains('John'));
      expect(greeting, endsWith('!'));

      container.dispose();
    });

    test('returns greeting without name when null', () {
      final container = ProviderContainer();

      final greeting = container.read(personalizedGreetingProvider(null));

      expect(greeting, isNot(contains(',')));
      expect(greeting, endsWith('!'));

      container.dispose();
    });

    test('returns greeting without name when empty string', () {
      final container = ProviderContainer();

      final greeting = container.read(personalizedGreetingProvider(''));

      expect(greeting, isNot(contains(',')));
      expect(greeting, endsWith('!'));

      container.dispose();
    });
  });

  group('homeTabProvider', () {
    test('initial value is HomeTab.home', () {
      final container = ProviderContainer();

      final tab = container.read(homeTabProvider);

      expect(tab, equals(HomeTab.home));

      container.dispose();
    });

    test('can change tab to calendar', () {
      final container = ProviderContainer();

      container.read(homeTabProvider.notifier).state = HomeTab.calendar;
      final tab = container.read(homeTabProvider);

      expect(tab, equals(HomeTab.calendar));

      container.dispose();
    });

    test('can change tab to profile', () {
      final container = ProviderContainer();

      container.read(homeTabProvider.notifier).state = HomeTab.profile;
      final tab = container.read(homeTabProvider);

      expect(tab, equals(HomeTab.profile));

      container.dispose();
    });

    test('can navigate between all tabs', () {
      final container = ProviderContainer();

      // Start at home
      expect(container.read(homeTabProvider), equals(HomeTab.home));

      // Go to calendar
      container.read(homeTabProvider.notifier).state = HomeTab.calendar;
      expect(container.read(homeTabProvider), equals(HomeTab.calendar));

      // Go to profile
      container.read(homeTabProvider.notifier).state = HomeTab.profile;
      expect(container.read(homeTabProvider), equals(HomeTab.profile));

      // Go back to home
      container.read(homeTabProvider.notifier).state = HomeTab.home;
      expect(container.read(homeTabProvider), equals(HomeTab.home));

      container.dispose();
    });
  });

  group('GreetingData', () {
    test('constructor sets all fields correctly', () {
      const data = GreetingData(
        greeting: 'Good morning',
        timePeriod: TimePeriod.morning,
        emoji: '\u{1F31E}',
      );

      expect(data.greeting, equals('Good morning'));
      expect(data.timePeriod, equals(TimePeriod.morning));
      expect(data.emoji, equals('\u{1F31E}'));
    });
  });

  group('TimePeriod enum', () {
    test('has all expected values', () {
      expect(TimePeriod.values.length, equals(4));
      expect(TimePeriod.values, contains(TimePeriod.morning));
      expect(TimePeriod.values, contains(TimePeriod.afternoon));
      expect(TimePeriod.values, contains(TimePeriod.evening));
      expect(TimePeriod.values, contains(TimePeriod.night));
    });
  });
}
