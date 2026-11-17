import 'package:calibre_web_companion/core/services/download_manager.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/ui/book_cover.dart';
import 'package:calibre_web_companion/shared/ui/book_stamp.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Widest a cover may get for the user's "columns" setting, in dp.
///
/// The setting used to be a fixed column count, which stretched covers on
/// tablets and in landscape. It now picks a cover size: 3 means about three
/// covers across a phone and proportionally more on wider screens.
double coverExtentFor(int columnSetting) => 420 / columnSetting.clamp(1, 6);

/// State stamps for [book], from what the app knows locally and from the
/// server. Only facts: read status and whether a copy is on this device.
List<StampKind> stampsFor(BookViewModel book, {bool? onDevice}) => [
  if (book.readStatus) const ReadStamp(),
  if (onDevice ??
      GetIt.instance.isRegistered<DownloadManager>() &&
          GetIt.instance<DownloadManager>().isBookDownloaded(book.uuid))
    const OnDeviceStamp(),
];

/// The cover wall: adaptive columns of jackets with title and author.
class LibraryGrid extends StatelessWidget {
  const LibraryGrid({
    super.key,
    required this.books,
    required this.columnSetting,
    required this.onOpen,
    this.controller,
    this.showLoadingTail = false,
    this.onDevice,
  });

  final List<BookViewModel> books;
  final int columnSetting;
  final ValueChanged<BookViewModel> onOpen;
  final ScrollController? controller;

  /// Adds a skeleton cell while the next page loads.
  final bool showLoadingTail;

  /// Overrides the download lookup (tests).
  final bool Function(BookViewModel)? onDevice;

  static const _padding = EdgeInsets.fromLTRB(12, 8, 12, 24);
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final maxExtent = coverExtentFor(columnSetting);
        final cellHeight = libraryCellHeight(
          context,
          availableWidth: box.maxWidth - _padding.horizontal,
          maxExtent: maxExtent,
        );
        return GridView.builder(
          controller: controller,
          // Keep pull-to-refresh working when the wall is short.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: _padding,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            crossAxisSpacing: _gap,
            mainAxisSpacing: 16,
            mainAxisExtent: cellHeight,
          ),
          itemCount: books.length + (showLoadingTail ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= books.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final book = books[index];
            return LibraryTile(
              book: book,
              stamps: stampsFor(book, onDevice: onDevice?.call(book)),
              onTap: () => onOpen(book),
            );
          },
        );
      },
    );
  }
}

/// Height of one grid cell: a 2:3 cover at the width the grid will actually
/// give it, plus two label lines at the current text scale. Mirrors how
/// [SliverGridDelegateWithMaxCrossAxisExtent] picks its column count.
double libraryCellHeight(
  BuildContext context, {
  required double availableWidth,
  required double maxExtent,
  double gap = 8,
}) {
  final columns = (availableWidth / (maxExtent + gap)).ceil().clamp(1, 99);
  final width = (availableWidth - gap * (columns - 1)) / columns;
  final style = Theme.of(context).textTheme.labelMedium!;
  final line =
      MediaQuery.textScalerOf(context).scale(style.fontSize!) *
      (style.height ?? 1.4);
  return width * 1.5 + 6 + line * 2 + 4;
}

/// One cover with its one-line title and author underneath.
class LibraryTile extends StatelessWidget {
  const LibraryTile({
    super.key,
    required this.book,
    required this.onTap,
    this.stamps = const [],
  });

  final BookViewModel book;
  final List<StampKind> stamps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final subtitle =
        book.seriesBadge == null
            ? book.authors
            : '${book.authors} · ${l10n.seriesNumber(book.series, book.seriesBadge!)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookCover(
          title: book.title,
          author: book.authors,
          bookId: book.id,
          coverUrl: book.coverUrl,
          stamps: stamps,
          onTap: onTap,
        ),
        const SizedBox(height: 6),
        // The cover already announces title and author.
        ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
