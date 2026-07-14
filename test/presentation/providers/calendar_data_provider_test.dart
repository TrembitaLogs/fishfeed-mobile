import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fishfeed/core/errors/failures.dart';
import 'package:fishfeed/domain/entities/calendar_month_data.dart';
import 'package:fishfeed/domain/usecases/get_calendar_data_usecase.dart';
import 'package:fishfeed/presentation/providers/calendar_data_provider.dart';

class MockGetCalendarDataUseCase extends Mock
    implements GetCalendarDataUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetCalendarDataParams(year: 2024, month: 1));
  });

  group('Notifier dispose safety (mounted guards)', () {
    test(
      'loadMonth does not throw when disposed during await (success branch)',
      () async {
        final useCase = MockGetCalendarDataUseCase();
        when(() => useCase(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Right<Failure, CalendarMonthData>(
            CalendarMonthData.empty(2024, 1),
          );
        });

        final notifier = CalendarDataNotifier(getCalendarDataUseCase: useCase);

        // Start the load, then dispose during the async gap.
        final future = notifier.loadMonth(2024, 1);
        notifier.dispose();

        // Without the mounted guard, the post-await `state =` inside the
        // success `.fold(...)` callback throws
        // "Tried to use CalendarDataNotifier after dispose was called".
        await expectLater(future, completes);
      },
    );

    test(
      'loadMonth does not throw when disposed during await (failure branch)',
      () async {
        final useCase = MockGetCalendarDataUseCase();
        when(() => useCase(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const Left<Failure, CalendarMonthData>(
            CacheFailure(message: 'boom'),
          );
        });

        final notifier = CalendarDataNotifier(getCalendarDataUseCase: useCase);

        // Start the load, then dispose during the async gap.
        final future = notifier.loadMonth(2024, 1);
        notifier.dispose();

        // Without the mounted guard, the post-await `state =` inside the
        // failure `.fold(...)` callback throws
        // "Tried to use CalendarDataNotifier after dispose was called".
        await expectLater(future, completes);
      },
    );
  });
}
