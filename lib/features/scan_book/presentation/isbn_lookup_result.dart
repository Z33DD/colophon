import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';

/// Outcome of one ISBN lookup. "Not found" and "could not look up" need
/// different UI: the first offers to edit the ISBN, the second to retry.
sealed class IsbnLookupResult {
  const IsbnLookupResult();
}

final class IsbnLookupFound extends IsbnLookupResult {
  const IsbnLookupFound(this.book);
  final IsbnBook book;
}

final class IsbnLookupNotFound extends IsbnLookupResult {
  const IsbnLookupNotFound();
}

final class IsbnLookupFailed extends IsbnLookupResult {
  const IsbnLookupFailed(this.error);
  final Object error;
}

/// Runs [lookup] and maps a thrown error to [IsbnLookupFailed] instead of
/// treating it like a missing book.
Future<IsbnLookupResult> classifyIsbnLookup(
  Future<IsbnBook?> Function(String isbn) lookup,
  String isbn,
) async {
  try {
    final book = await lookup(isbn);
    return book == null ? const IsbnLookupNotFound() : IsbnLookupFound(book);
  } catch (e) {
    return IsbnLookupFailed(e);
  }
}
