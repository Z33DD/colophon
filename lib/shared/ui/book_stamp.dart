import 'package:calibre_web_companion/core/theme/app_theme.dart';
import 'package:calibre_web_companion/core/theme/desk_colors.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// What a stamp states about a book. Stamps mark facts only.
sealed class StampKind {
  const StampKind();
}

/// Marked read, optionally on a known day.
final class ReadStamp extends StampKind {
  const ReadStamp([this.on]);
  final DateTime? on;
}

/// Reading position as a whole percentage (0-100).
final class ProgressStamp extends StampKind {
  const ProgressStamp(this.percent) : assert(percent >= 0 && percent <= 100);
  final int percent;
}

/// A local copy of the book is on this device.
final class OnDeviceStamp extends StampKind {
  const OnDeviceStamp();
}

/// The Circulation Desk ink stamp: condensed caps in a ruled box, tilted
/// like a hand stamp. Used on covers and in the book's slip.
class BookStamp extends StatelessWidget {
  const BookStamp(this.kind, {super.key, this.tilt = true});

  final StampKind kind;

  /// Off in lists where several stamps align, such as the book slip.
  final bool tilt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final desk = context.desk;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final (String text, Color ink) = switch (kind) {
      ReadStamp(:final on) => (
        on == null
            ? l10n.stampRead
            : l10n.stampReadOn(DateFormat('dd MMM', locale).format(on)),
        desk.stampRead,
      ),
      ProgressStamp(:final percent) => (
        l10n.stampProgress(percent),
        desk.stampProgress,
      ),
      OnDeviceStamp() => (l10n.stampOnDevice, desk.stampOnDevice),
    };

    final stamp = DecoratedBox(
      decoration: BoxDecoration(
        color: desk.stampPaper,
        border: Border.all(color: ink, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 3, 5, 2),
        child: Text(
          text.toUpperCase(),
          maxLines: 1,
          // Stamps keep their size; the label under the cover carries the
          // scaled text, so a 2x font scale doesn't bury the cover.
          textScaler: TextScaler.noScaling,
          style: AppTheme.stampStyle.copyWith(color: ink),
        ),
      ),
    );

    return Semantics(
      label: text,
      excludeSemantics: true,
      child: tilt ? Transform.rotate(angle: -0.105, child: stamp) : stamp,
    );
  }
}
