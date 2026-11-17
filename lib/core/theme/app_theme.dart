import 'package:calibre_web_companion/core/theme/desk_colors.dart';
import 'package:flutter/material.dart';

/// Builds the app's `ThemeData`.
///
/// [AppTheme.circulation] is the Circulation Desk identity (the default).
/// [AppTheme.fromScheme] applies the same component language to a dynamic
/// wallpaper scheme or a custom seed, which users can still choose.
abstract final class AppTheme {
  /// Family of the bundled condensed face used only for stamps and counters.
  static const stampFamily = 'BarlowCondensed';

  /// Stamp lettering: condensed caps. Size stays fixed relative to body text
  /// so a dense cover wall reads calm; rank comes from weight and case.
  static const stampStyle = TextStyle(
    fontFamily: stampFamily,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    height: 1,
    letterSpacing: 0.6,
  );

  /// Counters and section labels such as "2,481 books" or "Recently added".
  static const counterStyle = TextStyle(
    fontFamily: stampFamily,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    letterSpacing: 1.1,
  );

  static ThemeData circulation(Brightness brightness, {bool eInk = false}) {
    final scheme = eInk ? _eInkScheme : _circulationScheme(brightness);
    return _build(scheme, DeskColors.circulation(brightness, eInk: eInk));
  }

  static ThemeData fromScheme(ColorScheme scheme, {bool eInk = false}) {
    if (eInk) return circulation(Brightness.light, eInk: true);
    return _build(scheme, DeskColors.fromScheme(scheme));
  }

  static ColorScheme _circulationScheme(Brightness brightness) =>
      brightness == Brightness.light
          ? const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFF3E2A87),
            onPrimary: Color(0xFFFFFFFF),
            primaryContainer: Color(0xFFE4DEFA),
            onPrimaryContainer: Color(0xFF1E1147),
            secondary: Color(0xFF0B6E6D),
            onSecondary: Color(0xFFFFFFFF),
            secondaryContainer: Color(0xFFCDEDEB),
            onSecondaryContainer: Color(0xFF002120),
            tertiary: Color(0xFFB72C25),
            onTertiary: Color(0xFFFFFFFF),
            tertiaryContainer: Color(0xFFFFDAD5),
            onTertiaryContainer: Color(0xFF410001),
            error: Color(0xFFBA1A1A),
            onError: Color(0xFFFFFFFF),
            errorContainer: Color(0xFFFFDAD6),
            onErrorContainer: Color(0xFF410002),
            surface: Color(0xFFF3F3F6),
            onSurface: Color(0xFF17141F),
            onSurfaceVariant: Color(0xFF55506A),
            surfaceContainerLowest: Color(0xFFFFFFFF),
            surfaceContainerLow: Color(0xFFF8F8FA),
            surfaceContainer: Color(0xFFEDECF2),
            surfaceContainerHigh: Color(0xFFE7E6EE),
            surfaceContainerHighest: Color(0xFFE1E0E9),
            outline: Color(0xFF7D7891),
            outlineVariant: Color(0xFFD9D6E3),
            inverseSurface: Color(0xFF2D2A35),
            onInverseSurface: Color(0xFFF3F3F6),
            inversePrimary: Color(0xFFC9BEFF),
            shadow: Color(0xFF000000),
            scrim: Color(0xFF000000),
          )
          : const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFFC9BEFF),
            onPrimary: Color(0xFF24155E),
            primaryContainer: Color(0xFF3E2A87),
            onPrimaryContainer: Color(0xFFE6DEFF),
            secondary: Color(0xFF6FD6D3),
            onSecondary: Color(0xFF003736),
            secondaryContainer: Color(0xFF005150),
            onSecondaryContainer: Color(0xFF8DF2EF),
            tertiary: Color(0xFFFFB4A9),
            onTertiary: Color(0xFF690003),
            tertiaryContainer: Color(0xFF8F1D17),
            onTertiaryContainer: Color(0xFFFFDAD5),
            error: Color(0xFFFFB4AB),
            onError: Color(0xFF690005),
            errorContainer: Color(0xFF93000A),
            onErrorContainer: Color(0xFFFFDAD6),
            surface: Color(0xFF15121C),
            onSurface: Color(0xFFE7E3EF),
            onSurfaceVariant: Color(0xFFC9C3D9),
            surfaceContainerLowest: Color(0xFF100D17),
            surfaceContainerLow: Color(0xFF1D1925),
            surfaceContainer: Color(0xFF221E2A),
            surfaceContainerHigh: Color(0xFF2C2835),
            surfaceContainerHighest: Color(0xFF373340),
            outline: Color(0xFF938DA3),
            outlineVariant: Color(0xFF3A3546),
            inverseSurface: Color(0xFFE7E3EF),
            onInverseSurface: Color(0xFF2D2A35),
            inversePrimary: Color(0xFF3E2A87),
            shadow: Color(0xFF000000),
            scrim: Color(0xFF000000),
          );

  /// Pure black on white: e-ink panels render greys as noise and ghost.
  static const _eInkScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Colors.black,
    onPrimary: Colors.white,
    primaryContainer: Colors.white,
    onPrimaryContainer: Colors.black,
    secondary: Colors.black,
    onSecondary: Colors.white,
    tertiary: Colors.black,
    onTertiary: Colors.white,
    error: Colors.black,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    onSurfaceVariant: Colors.black,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: Colors.white,
    outline: Colors.black,
    outlineVariant: Colors.black,
  );

  static ThemeData _build(ColorScheme scheme, DeskColors desk) {
    // BorderSide width 0 paints a hairline: exactly one device pixel.
    final hairline = BorderSide(color: scheme.outlineVariant, width: 0);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [desk],
      // Predictive back on Android: the page follows the back gesture.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: desk.shell,
        foregroundColor: desk.onShell,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        side: hairline,
        shape: const StadiumBorder(),
        showCheckmark: false,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.primary,
        backgroundColor: scheme.surfaceContainerLowest,
        labelStyle: base.textTheme.labelLarge,
        secondaryLabelStyle: base.textTheme.labelLarge?.copyWith(
          color: scheme.onPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hairline,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        minVerticalPadding: 12,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
        constraints: const BoxConstraints(minHeight: 48),
      ),
    );
  }
}
