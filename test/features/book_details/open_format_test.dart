import 'package:calibre_web_companion/features/book_details/data/open_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a format already on the device is opened, not re-downloaded', () {
    // Regression: "Open in reader" always took formats.first (here PDF)
    // even though the EPUB was already downloaded.
    expect(chooseOpenFormat(['PDF', 'EPUB'], downloaded: {'epub'}), 'epub');
  });

  test('without a local copy EPUB is preferred', () {
    expect(chooseOpenFormat(['PDF', 'EPUB']), 'epub');
  });

  test('otherwise the server order decides', () {
    expect(chooseOpenFormat(['MOBI', 'PDF']), 'mobi');
    expect(chooseOpenFormat(const []), 'epub');
  });
}
