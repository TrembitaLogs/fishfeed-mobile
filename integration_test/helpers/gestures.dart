import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Swipe left (end-to-start) on the widget found by [finder].
Future<void> swipeLeft(WidgetTester tester, Finder finder) async {
  await tester.drag(finder, const Offset(-300, 0));
  await tester.pumpAndSettle();
}

/// Swipe right (start-to-end) on the widget found by [finder].
Future<void> swipeRight(WidgetTester tester, Finder finder) async {
  await tester.drag(finder, const Offset(300, 0));
  await tester.pumpAndSettle();
}

/// Long press on the widget found by [finder].
Future<void> longPress(WidgetTester tester, Finder finder) async {
  await tester.longPress(finder);
  await tester.pumpAndSettle();
}

/// Tap outside a bottom sheet to dismiss it (tap the barrier / scrim).
Future<void> tapOutsideSheet(WidgetTester tester) async {
  // The ModalBarrier sits behind the sheet; tapping it closes the modal.
  final barrier = find.byType(ModalBarrier).last;
  await tester.tap(barrier, warnIfMissed: false);
  await tester.pumpAndSettle();
}
