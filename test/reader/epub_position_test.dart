import 'dart:ui';

import 'package:cosmos_epub/Helpers/page_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveStartPage', () {
    test('a saved last page reopens on the last page', () {
      // Regression: the reader saved the last page of a chapter as page 0,
      // so stopping there reopened the book at the chapter start. The save
      // now keeps the index; restoring it must keep it too.
      expect(resolveStartPage(pageCount: 12, startIndex: 11), 11);
    });

    test('openAtEnd lands on the last page (turning back a chapter)', () {
      // Regression: turning back from a chapter's first page opened the
      // previous chapter at its first page instead of its last.
      expect(resolveStartPage(pageCount: 9, startIndex: openAtEnd), 8);
    });

    test('out-of-range or missing starts open at the beginning', () {
      expect(resolveStartPage(pageCount: 5, startIndex: 7), 0);
      expect(resolveStartPage(pageCount: 5, startIndex: 0), 0);
      expect(resolveStartPage(pageCount: 0, startIndex: 3), 0);
    });

    test('a fraction wins over a stored index', () {
      expect(resolveStartPage(pageCount: 10, startIndex: 2, fraction: 0.5), 5);
    });
  });

  test('pages are measured at exactly the size they are drawn', () {
    // Regression: the paginator measured 20 units narrower than the
    // screen while the page drew 40 units of side padding, so pages held
    // more text than fit and the rest hid in a vertical scroll.
    const insets = PageInsets(left: 20, right: 20, top: 60, bottom: 40);
    const screen = Size(400, 800);
    final measured = insets.contentSize(screen);

    expect(measured.width, screen.width - 40);
    expect(measured.height, screen.height - 100);
  });
}
