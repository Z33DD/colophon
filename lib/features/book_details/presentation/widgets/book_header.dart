import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/ui/book_cover.dart';
import 'package:calibre_web_companion/shared/ui/book_stamp.dart';
import 'package:flutter/material.dart';

/// Title block of book details: cover, title, author and series links, and
/// the read/archived toggles that state the book's current state.
///
/// On phones the cover sits beside the text; [coverWidth] lets the wide
/// layout put a large cover in its own pane instead (pass 0 to omit it).
class BookHeader extends StatelessWidget {
  const BookHeader({
    super.key,
    required this.book,
    required this.isRead,
    required this.isArchived,
    required this.onDevice,
    this.onToggleRead,
    this.onToggleArchived,
    this.onAuthorTap,
    this.onSeriesTap,
    this.coverWidth = 128,
    this.busyRead = false,
    this.busyArchived = false,
  });

  final BookDetailsModel book;
  final bool isRead;
  final bool isArchived;
  final bool onDevice;

  /// Null hides the toggle (server without read status).
  final VoidCallback? onToggleRead;
  final VoidCallback? onToggleArchived;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onSeriesTap;
  final double coverWidth;
  final bool busyRead;
  final bool busyArchived;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            book.title,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),
        _Link(
          text: book.authors,
          style: text.titleMedium?.copyWith(color: scheme.primary),
          onTap: onAuthorTap,
        ),
        if (book.series.isNotEmpty) ...[
          const SizedBox(height: 2),
          _Link(
            text: '${book.series} · ${book.seriesIndexLabel}',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            onTap: onSeriesTap,
          ),
        ],
        if (onToggleRead != null || onToggleArchived != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onToggleRead != null)
                _StateChip(
                  label: l10n.readToggle,
                  selected: isRead,
                  busy: busyRead,
                  onPressed: onToggleRead!,
                ),
              if (onToggleArchived != null)
                _StateChip(
                  label: l10n.archivedToggle,
                  selected: isArchived,
                  busy: busyArchived,
                  onPressed: onToggleArchived!,
                ),
            ],
          ),
        ],
      ],
    );

    if (coverWidth <= 0) return details;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: coverWidth,
          child: BookCover(
            title: book.title,
            author: book.authors,
            bookId: book.id,
            coverUrl: book.cover,
            stamps: [
              if (isRead) const ReadStamp(),
              if (onDevice) const OnDeviceStamp(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: details),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.text, required this.style, this.onTap});

  final String text;
  final TextStyle? style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = Text(text, style: style);
    if (onTap == null) return label;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Align(alignment: Alignment.centerLeft, child: label),
      ),
    );
  }
}

/// A toggle chip whose label names the state ("Read") and whose check mark
/// shows whether it applies, instead of an icon that shows the opposite.
class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final bool selected;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: !busy,
      checkmarkColor: scheme.onPrimary,
      avatar:
          busy
              ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : null,
      labelStyle: TextStyle(color: selected ? scheme.onPrimary : null),
      onSelected: busy ? null : (_) => onPressed(),
    );
  }
}
