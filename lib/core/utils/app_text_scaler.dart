import 'package:flutter/painting.dart';

/// Applies the in-app text size setting on top of the OS font size.
///
/// The in-app factor is relative: 1.0 means "use the system size". It must
/// never replace the system scaler, or users who enlarged text in Android or
/// iOS accessibility settings lose it inside the app. The system scaler may
/// be nonlinear (Android 14+ grows large fonts less than small ones), so this
/// delegates to it per font size instead of reading a single factor.
class AppTextScaler extends TextScaler {
  const AppTextScaler({required this.system, required this.appFactor})
    : assert(appFactor >= 0);

  /// The scaler from the platform `MediaQuery`.
  final TextScaler system;

  /// The user's in-app multiplier from Settings > Appearance.
  final double appFactor;

  @override
  double scale(double fontSize) => system.scale(fontSize) * appFactor;

  @override
  @Deprecated('Use scale() instead; kept to satisfy the TextScaler interface.')
  // ignore: deprecated_member_use
  double get textScaleFactor => system.textScaleFactor * appFactor;

  @override
  bool operator ==(Object other) =>
      other is AppTextScaler &&
      other.system == system &&
      other.appFactor == appFactor;

  @override
  int get hashCode => Object.hash(system, appFactor);

  @override
  String toString() => 'AppTextScaler($system × $appFactor)';
}
