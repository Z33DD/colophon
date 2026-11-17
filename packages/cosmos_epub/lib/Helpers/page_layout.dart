import 'dart:ui';

import 'package:cosmos_epub/Helpers/progress_mapping.dart';

/// Space between the screen edge and the text on an EPUB page.
///
/// The paginator measures text in [contentSize] and the page renders with
/// the same insets as padding. Both must come from one value: when they
/// differed, pages held more text than fit and the rest spilled into a
/// hidden vertical scroll.
class PageInsets {
  const PageInsets({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final double left;
  final double right;
  final double top;
  final double bottom;

  Size contentSize(Size page) =>
      Size(page.width - left - right, page.height - top - bottom);
}

/// Stored start index meaning "the chapter's last page", used when turning
/// back from the first page of a chapter into the previous one.
const int openAtEnd = -1;

/// Which page a chapter opens on.
///
/// [fraction] (a jump from KOReader or a bookmark) wins; otherwise the
/// stored [startIndex], [openAtEnd] for the last page, or 0 when the
/// stored index no longer fits the chapter's pages.
int resolveStartPage({
  required int pageCount,
  required int startIndex,
  double? fraction,
}) {
  if (pageCount <= 0) return 0;
  if (fraction != null) return pageIndexForFraction(fraction, pageCount);
  if (startIndex == openAtEnd) return pageCount - 1;
  return startIndex > 0 && startIndex < pageCount ? startIndex : 0;
}
