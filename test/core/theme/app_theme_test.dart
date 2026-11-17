import 'package:calibre_web_companion/core/theme/app_theme.dart';
import 'package:calibre_web_companion/core/theme/desk_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    group('Circulation Desk ${brightness.name}', () {
      final theme = AppTheme.circulation(brightness);
      final scheme = theme.colorScheme;
      final desk = theme.extension<DeskColors>()!;

      test('body text and secondary text meet 4.5:1 on the ground', () {
        expect(contrast(scheme.onSurface, scheme.surface), greaterThan(4.5));
        expect(
          contrast(scheme.onSurfaceVariant, scheme.surface),
          greaterThan(4.5),
        );
      });

      test('shell bar text meets 4.5:1', () {
        expect(contrast(desk.onShell, desk.shell), greaterThan(4.5));
        expect(contrast(desk.onShellMuted, desk.shell), greaterThan(4.5));
      });

      test('every stamp ink meets 4.5:1 on stamp paper', () {
        for (final ink in [
          desk.stampRead,
          desk.stampProgress,
          desk.stampOnDevice,
        ]) {
          expect(contrast(ink, desk.stampPaper), greaterThan(4.5));
        }
      });

      test('primary actions meet 4.5:1', () {
        expect(contrast(scheme.onPrimary, scheme.primary), greaterThan(4.5));
      });
    });
  }

  test('e-ink theme uses pure black on white with black stamps', () {
    final theme = AppTheme.circulation(Brightness.light, eInk: true);
    final desk = theme.extension<DeskColors>()!;

    expect(theme.colorScheme.surface, Colors.white);
    expect(theme.colorScheme.onSurface, Colors.black);
    expect(desk.stampRead, Colors.black);
    expect(desk.stampProgress, Colors.black);
    expect(desk.stampOnDevice, Colors.black);
    expect(desk.coverShadow, isEmpty, reason: 'shadows ghost on e-ink');
  });

  test('a dynamic or custom scheme still gets desk colours from its roles', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
    final theme = AppTheme.fromScheme(scheme);

    expect(theme.extension<DeskColors>()!.shell, scheme.primary);
  });

  test('desk colours interpolate for animated theme changes', () {
    final light = DeskColors.circulation(Brightness.light);
    final dark = DeskColors.circulation(Brightness.dark);

    expect(light.lerp(dark, 0).shell, light.shell);
    expect(light.lerp(dark, 1).shell, dark.shell);
  });
}
