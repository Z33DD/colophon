import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/sync/bloc/sync_state.dart';
import 'package:calibre_web_companion/features/sync/data/models/sync_format_choice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chooseSyncFormat', () {
    test('picks the first wanted format the book has', () {
      final choice = chooseSyncFormat(['PDF', 'EPUB'], ['azw3', 'epub']);
      expect(choice.format, 'epub');
      expect(choice.skipReason, isNull);
    });

    test('matches servers that append sizes to format names', () {
      expect(chooseSyncFormat(['EPUB (1.2 MB)'], ['epub']).format, 'epub');
    });

    test('reports why a book is skipped when no wanted format exists', () {
      // Regression: skipped books were recorded as generic errors, so the
      // user only saw "finished with N errors".
      final choice = chooseSyncFormat(['PDF'], ['epub']);
      expect(choice.format, isNull);
      expect(choice.skipReason, SyncSkipReason.noMatchingFormat);
    });

    test('without a format filter prefers EPUB, then the first format', () {
      expect(chooseSyncFormat(['PDF', 'EPUB'], const []).format, 'epub');
      expect(chooseSyncFormat(['MOBI', 'PDF'], const []).format, 'MOBI');
    });

    test('a book with no formats is skipped with its own reason', () {
      expect(
        chooseSyncFormat(const [], const []).skipReason,
        SyncSkipReason.noFormats,
      );
    });
  });

  test('a skipped queue item keeps its reason through copyWith', () {
    // copyWith must not drop the reason the UI shows.
    const item = SyncQueueItem(
      book: _book,
      status: SyncQueueItem.skipped,
      skipReason: SyncSkipReason.noMatchingFormat,
    );
    expect(item.copyWith().skipReason, SyncSkipReason.noMatchingFormat);
  });
}

const _book = BookViewModel(
  id: 1,
  uuid: 'u-1',
  title: 'Dune',
  authors: 'Herbert',
);
