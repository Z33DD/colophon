import 'dart:async';

/// What changed about a book. Lists use it to refresh or drop a row.
enum BookChange { readStatus, archived, metadata, shelves, deleted, download }

/// A book changed somewhere in the app.
class BookChanged {
  const BookChanged(this.bookId, this.change, {this.read});
  final int bookId;
  final BookChange change;

  /// New read status for [BookChange.readStatus].
  final bool? read;
}

/// App-wide broadcast of book changes.
///
/// Book details publishes; Library, shelf and discover lists subscribe and
/// refresh, so going back always shows the current state. This replaces
/// returning a "did update" flag through `Navigator.pop`, which forced
/// `PopScope(canPop: false)` and broke predictive back.
///
/// Registered as a singleton in get_it. Events are not replayed: a list
/// built after the change loads fresh data anyway.
class LibraryEvents {
  final _controller = StreamController<BookChanged>.broadcast();

  Stream<BookChanged> get stream => _controller.stream;

  void publish(BookChanged event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}
