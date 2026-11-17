import 'package:cosmos_epub/Helpers/page_layout.dart';
import 'package:cosmos_epub/Helpers/reader_position.dart';
import 'package:cosmos_epub/Model/book_progress_model.dart';
import 'package:get_storage/get_storage.dart';

class BookProgressSingleton {
  static const String containerName = 'cosmos_epub_progress';

  final GetStorage _box;

  BookProgressSingleton({GetStorage? box})
      : _box = box ?? GetStorage(containerName);

  String _key(String bookId) => 'progress_$bookId';

  /// The stored position, migrating legacy `{chapter, page}` records.
  ReaderPosition getPosition(String bookId) {
    try {
      return ReaderPosition.fromStored(_box.read(_key(bookId)));
    } catch (_) {
      return const ReaderPosition(chapter: 0);
    }
  }

  BookProgressModel getBookProgress(String bookId) {
    final position = getPosition(bookId);
    return BookProgressModel(
      bookId: bookId,
      currentChapterIndex: position.chapter,
      currentPageIndex: position.page,
      chapterFraction: position.fraction,
    );
  }

  /// Moves to [chapterIndex] and keeps the stored page target, which the
  /// callers set first (0 for a chapter start, [openAtEnd] for its end).
  Future<bool> setCurrentChapterIndex(String bookId, int chapterIndex) =>
      _write(bookId, getPosition(bookId).copyWith(chapter: chapterIndex));

  /// Sets an explicit page target and drops the fraction, so the page wins.
  Future<bool> setCurrentPageIndex(String bookId, int pageIndex) =>
      _write(bookId, getPosition(bookId).atPage(pageIndex));

  /// Records the page on screen and its share of the chapter. This is the
  /// save that survives a font or size change.
  Future<bool> setPagePosition(String bookId, int pageIndex, int pageCount) {
    final current = getPosition(bookId);
    return _write(
      bookId,
      ReaderPosition.onPage(
        chapter: current.chapter,
        page: pageIndex,
        pageCount: pageCount,
      ),
    );
  }

  /// Replaces the whole position, e.g. with one restored from sync.
  Future<bool> setPosition(String bookId, ReaderPosition position) =>
      _write(bookId, position);

  Future<bool> _write(String bookId, ReaderPosition position) async {
    try {
      await _box.write(_key(bookId), position.toStored());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBookProgress(String bookId) async {
    try {
      await _box.remove(_key(bookId));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAllBooksProgress() async {
    try {
      await _box.erase();
      return true;
    } catch (_) {
      return false;
    }
  }
}
