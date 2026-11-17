import 'dart:io';

import 'package:calibre_web_companion/features/scan_book/data/models/isbn_book.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/isbn_lookup_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyIsbnLookup', () {
    test('a thrown error is a failure, not "not found"', () async {
      // Regression: a network error showed a "lookup failed" snackbar AND
      // the "ISBN not found" dialog, which contradict each other.
      final result = await classifyIsbnLookup(
        (_) async => throw const SocketException('offline'),
        '9780441172719',
      );
      expect(result, isA<IsbnLookupFailed>());
    });

    test('no match is "not found"', () async {
      final result = await classifyIsbnLookup((_) async => null, '123');
      expect(result, isA<IsbnLookupNotFound>());
    });

    test('a match carries the book', () async {
      const book = IsbnBook(isbn: '9780441172719', title: 'Dune');
      final result = await classifyIsbnLookup((_) async => book, 'x');
      expect((result as IsbnLookupFound).book, book);
    });
  });
}
