import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fishfeed/core/utils/scroll_padding.dart';

void main() {
  /// Builds [child] under a MediaQuery reporting [bottom] as safe-area inset.
  Widget wrap(double bottom, WidgetBuilder builder) => MediaQuery(
    data: MediaQueryData(padding: EdgeInsets.only(bottom: bottom)),
    child: Builder(builder: builder),
  );

  group('withBottomSafeArea', () {
    testWidgets('adds the safe-area inset to the bottom edge', (tester) async {
      late EdgeInsets result;

      await tester.pumpWidget(
        wrap(48, (context) {
          result = const EdgeInsets.all(16).withBottomSafeArea(context);
          return const SizedBox();
        }),
      );

      expect(result.bottom, 64);
    });

    testWidgets('leaves the other edges untouched', (tester) async {
      late EdgeInsets result;

      await tester.pumpWidget(
        wrap(48, (context) {
          result = const EdgeInsets.fromLTRB(
            16,
            8,
            24,
            4,
          ).withBottomSafeArea(context);
          return const SizedBox();
        }),
      );

      expect(result.left, 16);
      expect(result.top, 8);
      expect(result.right, 24);
    });

    testWidgets('is a no-op when the inset is already consumed', (
      tester,
    ) async {
      // A Scaffold with a bottomNavigationBar zeroes the inset for its body,
      // so the helper must not stack padding on top of it.
      late EdgeInsets result;

      await tester.pumpWidget(
        wrap(0, (context) {
          result = const EdgeInsets.all(16).withBottomSafeArea(context);
          return const SizedBox();
        }),
      );

      expect(result.bottom, 16);
    });
  });
}
