import 'package:flutter/material.dart';

/// Colours of the Circulation Desk world that Material's `ColorScheme` has
/// no role for: the shell bar and the ink of each state stamp.
///
/// Stamps mark facts about a book, never decoration:
/// - [stampRead]: the book is marked read (with the date).
/// - [stampProgress]: reading position or percentage.
/// - [stampOnDevice]: a local copy exists.
@immutable
class DeskColors extends ThemeExtension<DeskColors> {
  const DeskColors({
    required this.shell,
    required this.onShell,
    required this.onShellMuted,
    required this.stampRead,
    required this.stampProgress,
    required this.stampOnDevice,
    required this.stampPaper,
    required this.coverShadow,
  });

  /// Background of the top app bar and other shell chrome.
  final Color shell;
  final Color onShell;

  /// Secondary text on [shell], such as the book count.
  final Color onShellMuted;

  final Color stampRead;
  final Color stampProgress;
  final Color stampOnDevice;

  /// Backing behind a stamp so it stays legible on any cover.
  final Color stampPaper;

  /// Shadow under covers. Empty on e-ink, where shadows ghost.
  final List<BoxShadow> coverShadow;

  static const _violet = Color(0xFF3E2A87);
  static const _red = Color(0xFFB72C25);
  static const _teal = Color(0xFF0B6E6D);

  factory DeskColors.circulation(Brightness brightness, {bool eInk = false}) {
    if (eInk) {
      return const DeskColors(
        shell: Colors.black,
        onShell: Colors.white,
        onShellMuted: Colors.white,
        stampRead: Colors.black,
        stampProgress: Colors.black,
        stampOnDevice: Colors.black,
        stampPaper: Colors.white,
        coverShadow: [],
      );
    }
    if (brightness == Brightness.light) {
      return const DeskColors(
        shell: _violet,
        onShell: Colors.white,
        onShellMuted: Color(0xFFD9D1F7),
        stampRead: _violet,
        stampProgress: _red,
        stampOnDevice: _teal,
        stampPaper: Color(0xF2FFFFFF),
        coverShadow: [
          BoxShadow(
            color: Color(0x2E17141F),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x1A17141F),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      );
    }
    return const DeskColors(
      shell: Color(0xFF251B4F),
      onShell: Color(0xFFF1EDFF),
      onShellMuted: Color(0xFFC3B8EE),
      stampRead: Color(0xFFCFC4FF),
      stampProgress: Color(0xFFFFB4A9),
      stampOnDevice: Color(0xFF7FDDD9),
      stampPaper: Color(0xF015121C),
      coverShadow: [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  /// Desk colours for a dynamic (wallpaper) or custom-seed scheme, mapped
  /// from its roles so stamps still carry distinct meanings.
  factory DeskColors.fromScheme(ColorScheme scheme) => DeskColors(
    shell: scheme.primary,
    onShell: scheme.onPrimary,
    onShellMuted: scheme.onPrimary.withValues(alpha: 0.85),
    stampRead: scheme.primary,
    stampProgress: scheme.tertiary,
    stampOnDevice: scheme.secondary,
    stampPaper: scheme.surface.withValues(alpha: 0.94),
    coverShadow:
        scheme.brightness == Brightness.light
            ? const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ]
            : const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
  );

  @override
  DeskColors copyWith({
    Color? shell,
    Color? onShell,
    Color? onShellMuted,
    Color? stampRead,
    Color? stampProgress,
    Color? stampOnDevice,
    Color? stampPaper,
    List<BoxShadow>? coverShadow,
  }) => DeskColors(
    shell: shell ?? this.shell,
    onShell: onShell ?? this.onShell,
    onShellMuted: onShellMuted ?? this.onShellMuted,
    stampRead: stampRead ?? this.stampRead,
    stampProgress: stampProgress ?? this.stampProgress,
    stampOnDevice: stampOnDevice ?? this.stampOnDevice,
    stampPaper: stampPaper ?? this.stampPaper,
    coverShadow: coverShadow ?? this.coverShadow,
  );

  @override
  DeskColors lerp(ThemeExtension<DeskColors>? other, double t) {
    if (other is! DeskColors) return this;
    return DeskColors(
      shell: Color.lerp(shell, other.shell, t)!,
      onShell: Color.lerp(onShell, other.onShell, t)!,
      onShellMuted: Color.lerp(onShellMuted, other.onShellMuted, t)!,
      stampRead: Color.lerp(stampRead, other.stampRead, t)!,
      stampProgress: Color.lerp(stampProgress, other.stampProgress, t)!,
      stampOnDevice: Color.lerp(stampOnDevice, other.stampOnDevice, t)!,
      stampPaper: Color.lerp(stampPaper, other.stampPaper, t)!,
      coverShadow: BoxShadow.lerpList(coverShadow, other.coverShadow, t)!,
    );
  }
}

/// Shorthand: `context.desk.stampRead`.
extension DeskColorsContext on BuildContext {
  DeskColors get desk =>
      Theme.of(this).extension<DeskColors>() ??
      DeskColors.fromScheme(Theme.of(this).colorScheme);
}
