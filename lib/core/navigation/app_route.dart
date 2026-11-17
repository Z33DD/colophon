import 'package:flutter/material.dart';

/// The one route type for full-screen pages.
///
/// It is a [MaterialPageRoute], so the theme's `PageTransitionsTheme`
/// decides the animation (Android predictive back). When the platform asks
/// for reduced motion, or e-ink mode is on (main.dart folds e-ink into
/// `MediaQuery.disableAnimations`), pages appear without a transition.
class AppRoute<T> extends MaterialPageRoute<T> {
  AppRoute({required super.builder, super.settings, super.fullscreenDialog});

  /// Route for an already-built [page].
  static AppRoute<T> page<T>(Widget page, {RouteSettings? settings}) =>
      AppRoute<T>(builder: (_) => page, settings: settings);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
