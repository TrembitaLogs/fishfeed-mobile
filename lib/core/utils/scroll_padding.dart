import 'package:flutter/widgets.dart';

/// Safe-area helpers for the padding of scrollable views.
///
/// Flutter injects the bottom safe-area inset into a scroll view automatically
/// only when [BoxScrollView.padding] is null — and [SingleChildScrollView]
/// never does it at all. Passing an explicit padding therefore silently drops
/// the inset, and since Android 15 enforces edge-to-edge (targetSdk 35), the
/// system navigation bar then covers the last item with no way to scroll it
/// into view.
extension ScrollPaddingExtensions on EdgeInsets {
  /// Returns this padding with the bottom safe-area inset added to [bottom].
  ///
  /// Use it on every scroll view that passes an explicit padding and is not
  /// already wrapped in a [SafeArea]:
  ///
  /// ```dart
  /// ListView(
  ///   padding: const EdgeInsets.all(16).withBottomSafeArea(context),
  ///   children: items,
  /// )
  /// ```
  ///
  /// Safe to apply unconditionally: a [Scaffold] with a `bottomNavigationBar`
  /// already consumes the inset for its body, so the value resolves to zero
  /// there and the padding is left as-is.
  EdgeInsets withBottomSafeArea(BuildContext context) =>
      copyWith(bottom: bottom + MediaQuery.paddingOf(context).bottom);
}
