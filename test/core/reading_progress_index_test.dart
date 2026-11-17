import 'package:calibre_web_companion/core/services/reading_progress_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a recorded percentage is kept per book', () async {
    // Regression: the reader reported progress but nothing kept it, so
    // covers and book details never showed how far you had read.
    SharedPreferences.setMockInitialValues({});
    final index = ReadingProgressIndex(await SharedPreferences.getInstance());

    await index.record('dune', 63.6);
    await index.record('emma', 12);

    expect(index.percentFor('dune'), closeTo(63.6, 1e-9));
    expect(index.stampPercentFor('dune'), 64);
    expect(index.percentFor('unknown'), isNull);
  });

  test('unstarted and finished books get no progress stamp', () async {
    SharedPreferences.setMockInitialValues({});
    final index = ReadingProgressIndex(await SharedPreferences.getInstance());
    await index.record('a', 0.4);
    await index.record('b', 99);

    expect(index.stampPercentFor('a'), isNull);
    expect(index.stampPercentFor('b'), isNull);
  });
}
