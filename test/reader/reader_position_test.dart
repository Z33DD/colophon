import 'package:cosmos_epub/Helpers/page_layout.dart';
import 'package:cosmos_epub/Helpers/reader_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReaderPosition saved(int page, int pageCount) =>
      ReaderPosition.onPage(chapter: 3, page: page, pageCount: pageCount);

  ReaderPosition reload(ReaderPosition position) =>
      ReaderPosition.fromStored(position.toStored());

  group('same layout round trip', () {
    test('start, middle and end reopen on the same page', () {
      for (final page in [0, 7, 19]) {
        expect(reload(saved(page, 20)).pageIn(20), page, reason: 'page $page');
      }
    });

    test('the chapter survives the round trip', () {
      expect(reload(saved(5, 20)).chapter, 3);
    });
  });

  group('after the layout changes', () {
    test('a bigger font keeps the same share of the chapter', () {
      // Regression: the reader stored only a page number, so page 10 of 20
      // became page 10 of 40 after a font change, a quarter of the way in.
      expect(reload(saved(10, 21)).pageIn(41), 20);
    });

    test('the last page stays the last page', () {
      expect(reload(saved(19, 20)).pageIn(7), 6);
    });

    test('the first page stays the first page', () {
      expect(reload(saved(0, 20)).pageIn(50), 0);
    });
  });

  group('migration from {chapter, page}', () {
    test('a legacy record opens on its stored page', () {
      final legacy = ReaderPosition.fromStored({'chapter': 2, 'page': 4});
      expect(legacy.chapter, 2);
      expect(legacy.fraction, isNull);
      expect(legacy.pageIn(10), 4);
    });

    test('the next save adds a fraction', () {
      final legacy = ReaderPosition.fromStored({'chapter': 2, 'page': 4});
      final next = ReaderPosition.onPage(
          chapter: legacy.chapter, page: 5, pageCount: 11);
      expect(next.toStored(), {'chapter': 2, 'page': 5, 'fraction': 0.5});
    });

    test('a legacy page past the end opens at the chapter start', () {
      expect(ReaderPosition.fromStored({'chapter': 1, 'page': 30}).pageIn(8),
          0);
    });

    test('missing or broken records open at the start', () {
      for (final raw in [null, 'x', 7, <String, Object>{}]) {
        final position = ReaderPosition.fromStored(raw);
        expect(position.chapter, 0, reason: '$raw');
        expect(position.pageIn(10), 0, reason: '$raw');
      }
    });

    test('out-of-range fractions are clamped', () {
      final position =
          ReaderPosition.fromStored({'chapter': 0, 'page': 0, 'fraction': 3});
      expect(position.pageIn(10), 9);
    });
  });

  group('explicit page targets', () {
    test('atPage drops the fraction so openAtEnd wins', () {
      final turnedBack = reload(saved(0, 20).atPage(openAtEnd));
      expect(turnedBack.fraction, isNull);
      expect(turnedBack.pageIn(12), 11);
    });

    test('atPage(0) opens the next chapter at its start', () {
      expect(reload(saved(19, 20).atPage(0)).pageIn(12), 0);
    });
  });

  test('fractionForPage handles one-page chapters', () {
    expect(fractionForPage(0, 1), 0);
    expect(fractionForPage(0, 0), 0);
  });
}
