import 'dart:async';

import 'package:calibre_web_companion/core/utils/latest_only.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/library_filter.dart';
import 'package:flutter_test/flutter_test.dart';

const _hobbit = BookViewModel(
  id: 1,
  uuid: 'h',
  title: 'The Hobbit',
  authors: 'J. R. R. Tolkien',
  series: 'Middle-earth',
  tags: ['Fantasy'],
);
const _letters = BookViewModel(
  id: 2,
  uuid: 'l',
  title: 'Letters from Father Christmas',
  authors: 'Baillie Tolkien, J. R. R. Tolkien',
);
const _about = BookViewModel(
  id: 3,
  uuid: 'a',
  title: 'Tolkien: A Biography',
  authors: 'Humphrey Carpenter',
);

void main() {
  group('matchesScope', () {
    test('an author suggestion matches that author, not the word', () {
      // Regression: picking the author "J. R. R. Tolkien" searched free
      // text and also listed books *about* Tolkien.
      final hits = [_hobbit, _letters, _about].where(
        (b) => matchesScope(b, SearchScope.author, 'J. R. R. Tolkien'),
      );
      expect(hits, [_hobbit, _letters]);
    });

    test('series and tag scopes match exactly, ignoring case', () {
      expect(matchesScope(_hobbit, SearchScope.series, 'middle-earth'), isTrue);
      expect(matchesScope(_hobbit, SearchScope.series, 'middle'), isFalse);
      expect(matchesScope(_hobbit, SearchScope.tag, 'fantasy'), isTrue);
    });

    test('free text keeps every server result', () {
      expect(matchesScope(_about, SearchScope.any, 'tolkien'), isTrue);
    });
  });

  group('LibraryFilter', () {
    test('each filter maps to its OPDS list', () {
      expect(LibraryFilter.all.opdsPath, isNull);
      expect(LibraryFilter.unread.opdsPath, '/opds/unreadbooks');
      expect(LibraryFilter.read.opdsPath, '/opds/readbooks');
      expect(const LibraryFilter.format('EPUB').opdsPath, '/opds/formats/epub');
    });

    test('read lists imply the read flag OPDS does not carry', () {
      expect(LibraryFilter.read.impliedReadStatus, isTrue);
      expect(LibraryFilter.unread.impliedReadStatus, isFalse);
      expect(LibraryFilter.all.impliedReadStatus, isNull);
    });
  });

  test('LatestOnly drops a slow older response', () async {
    final latest = LatestOnly();
    final slow = Completer<String>();
    final fast = Completer<String>();

    final first = latest.run(() => slow.future); // "to"
    final second = latest.run(() => fast.future); // "tolk"
    fast.complete('tolk');
    slow.complete('to');

    expect(await second, 'tolk');
    expect(await first, isNull, reason: 'superseded');
  });
}
