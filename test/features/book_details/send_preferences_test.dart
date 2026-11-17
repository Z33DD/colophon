import 'package:calibre_web_companion/features/book_details/data/send_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the last method, device and format come back next time', () async {
    // Regression: the dialog reset to Browser + Kobo on every send, and
    // email always sent EPUB.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await const SendPreferences(
      method: SendMethod.email,
      kindle: true,
      format: 'azw3',
    ).save(prefs);
    final loaded = SendPreferences.load(prefs);

    expect(loaded.method, SendMethod.email);
    expect(loaded.kindle, isTrue);
    expect(loaded.formatFor(['EPUB', 'AZW3']), 'azw3');
  });

  test('defaults are Browser, Kobo and EPUB', () async {
    SharedPreferences.setMockInitialValues({});
    final loaded = SendPreferences.load(await SharedPreferences.getInstance());

    expect(loaded.method, SendMethod.browser);
    expect(loaded.kindle, isFalse);
    expect(loaded.formatFor(['PDF', 'EPUB']), 'epub');
  });

  test('a remembered format the book lacks falls back', () {
    expect(const SendPreferences(format: 'azw3').formatFor(['PDF']), 'pdf');
  });
}
