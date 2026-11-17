import 'package:cosmos_epub/Helpers/page_layout.dart';

/// Where the reader is in a book: a chapter, and how far into it (0-1).
///
/// Pages are not a stable unit. They depend on the screen, font, size and
/// margins, so a stored page number points somewhere else after any of
/// those change. The [fraction] does not, and it is what restores the
/// position. [page] is kept for two cases a fraction cannot express:
/// records written before fractions existed, and [openAtEnd].
class ReaderPosition {
  const ReaderPosition({required this.chapter, this.page = 0, this.fraction});

  /// Index into the flattened chapter list.
  final int chapter;

  /// Page index on the layout that saved it, or [openAtEnd].
  final int page;

  /// Share of the chapter, 0 at its first page and 1 at its last. Null for
  /// legacy records and for explicit page targets (chapter start or end).
  final double? fraction;

  /// Reads a stored record. Legacy `{chapter, page}` records load with no
  /// fraction, open on their stored page once, and gain a fraction on the
  /// next page turn. Anything unreadable opens the book at the start.
  factory ReaderPosition.fromStored(Object? raw) {
    if (raw is! Map) return const ReaderPosition(chapter: 0);
    final chapter = (raw['chapter'] as num?)?.toInt() ?? 0;
    final page = (raw['page'] as num?)?.toInt() ?? 0;
    final fraction = (raw['fraction'] as num?)?.toDouble();
    return ReaderPosition(
      chapter: chapter < 0 ? 0 : chapter,
      page: page,
      fraction: fraction == null || fraction.isNaN
          ? null
          : fraction.clamp(0.0, 1.0).toDouble(),
    );
  }

  /// The position of [page] in a chapter laid out as [pageCount] pages.
  factory ReaderPosition.onPage({
    required int chapter,
    required int page,
    required int pageCount,
  }) =>
      ReaderPosition(
        chapter: chapter,
        page: page,
        fraction: fractionForPage(page, pageCount),
      );

  Map<String, Object> toStored() => {
        'chapter': chapter,
        'page': page,
        if (fraction != null) 'fraction': fraction!,
      };

  /// The page to open on when the chapter has [pageCount] pages now.
  int pageIn(int pageCount) => resolveStartPage(
        pageCount: pageCount,
        startIndex: page,
        fraction: fraction,
      );

  ReaderPosition copyWith({int? chapter, int? page, double? fraction}) =>
      ReaderPosition(
        chapter: chapter ?? this.chapter,
        page: page ?? this.page,
        fraction: fraction ?? this.fraction,
      );

  /// Same chapter, an explicit page target, no fraction.
  ReaderPosition atPage(int page) =>
      ReaderPosition(chapter: chapter, page: page);
}

/// The inverse of `pageIndexForFraction`: page 0 is 0, the last page is 1,
/// so a round trip on the same layout lands on the same page.
double fractionForPage(int page, int pageCount) {
  if (pageCount <= 1 || page <= 0) return 0;
  if (page >= pageCount - 1) return 1;
  return page / (pageCount - 1);
}
