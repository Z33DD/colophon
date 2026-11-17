import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:equatable/equatable.dart';

/// Which slice of the library is listed. One at a time: Calibre-Web serves
/// each slice as its own OPDS list, and they cannot be combined.
enum LibraryFilterKind { all, unread, read, format }

class LibraryFilter extends Equatable {
  const LibraryFilter._(this.kind, [this.format]);

  static const all = LibraryFilter._(LibraryFilterKind.all);
  static const unread = LibraryFilter._(LibraryFilterKind.unread);
  static const read = LibraryFilter._(LibraryFilterKind.read);

  /// Books available in [format] (e.g. "epub"), as the server names it.
  const LibraryFilter.format(String format)
    : this._(LibraryFilterKind.format, format);

  final LibraryFilterKind kind;
  final String? format;

  bool get isAll => kind == LibraryFilterKind.all;

  /// The OPDS list that serves this filter. Null for [all], which uses the
  /// sortable `/ajax/listbooks` endpoint instead.
  String? get opdsPath => switch (kind) {
    LibraryFilterKind.all => null,
    LibraryFilterKind.unread => '/opds/unreadbooks',
    LibraryFilterKind.read => '/opds/readbooks',
    LibraryFilterKind.format =>
      '/opds/formats/${Uri.encodeComponent(format!.toLowerCase())}',
  };

  /// OPDS entries carry no read flag; the list itself says it.
  bool? get impliedReadStatus => switch (kind) {
    LibraryFilterKind.read => true,
    LibraryFilterKind.unread => false,
    _ => null,
  };

  @override
  List<Object?> get props => [kind, format];
}

/// What a search term should match. Typed suggestions (an author, a series,
/// a tag) narrow results to that field instead of a free-text match.
enum SearchScope { any, title, author, series, tag }

/// Whether [book] matches [term] for [scope]. Case-insensitive; authors and
/// tags match one entry of the list, series match exactly.
bool matchesScope(BookViewModel book, SearchScope scope, String term) {
  final needle = term.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return switch (scope) {
    SearchScope.any => true,
    SearchScope.title => book.title.toLowerCase().contains(needle),
    SearchScope.author => book.authors
        .split(RegExp(r'\s*[,&]\s*'))
        .any((a) => a.trim().toLowerCase() == needle),
    SearchScope.series => book.series.trim().toLowerCase() == needle,
    SearchScope.tag => book.tags.any((t) => t.trim().toLowerCase() == needle),
  };
}
