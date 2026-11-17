import 'package:calibre_web_companion/features/settings/presentation/widgets/reachable_url_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only full http(s) addresses count as valid', () {
    // Regression: the Send-to-eReader URL saved on every keystroke, so a
    // half-typed "htp:/x" replaced the working address.
    expect(isValidServerUrl('htp:/x'), isFalse);
    expect(isValidServerUrl('books.home'), isFalse);
    expect(isValidServerUrl('https://'), isFalse);
    expect(isValidServerUrl('https://bookdrop.cc'), isTrue);
    expect(isValidServerUrl('http://192.168.1.10:8083/'), isTrue);
  });
}
