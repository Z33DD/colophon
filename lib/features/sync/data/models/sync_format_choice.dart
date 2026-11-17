import 'package:calibre_web_companion/features/sync/bloc/sync_state.dart';

/// Which format sync should download for a book, or why it skips the book.
/// Exactly one of [format] and [skipReason] is non-null.
typedef SyncFormatChoice = ({String? format, SyncSkipReason? skipReason});

/// Picks the format to sync from the server's [bookFormats].
///
/// With [wantedFormats] (the sync filter) the first wanted format the book
/// has wins; servers that report "EPUB (1.2 MB)" still match. Without a
/// filter EPUB is preferred, then the first format the server lists.
SyncFormatChoice chooseSyncFormat(
  List<String> bookFormats,
  List<String> wantedFormats,
) {
  if (bookFormats.isEmpty) {
    return (format: null, skipReason: SyncSkipReason.noFormats);
  }

  if (wantedFormats.isEmpty) {
    final hasEpub = bookFormats.any((f) => f.toUpperCase() == 'EPUB');
    return (format: hasEpub ? 'epub' : bookFormats.first, skipReason: null);
  }

  final available = bookFormats.map((f) => f.toLowerCase().trim()).toList();
  for (final wanted in wantedFormats) {
    if (available.contains(wanted.toLowerCase().trim())) {
      return (format: wanted, skipReason: null);
    }
  }
  for (final wanted in wantedFormats) {
    final format = wanted.toLowerCase().trim();
    if (available.any((f) => f.contains(format))) {
      return (format: wanted, skipReason: null);
    }
  }
  return (format: null, skipReason: SyncSkipReason.noMatchingFormat);
}
