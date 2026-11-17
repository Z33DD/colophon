import 'package:calibre_web_companion/core/services/library_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every subscriber receives a published change', () async {
    final events = LibraryEvents();
    final a = <BookChanged>[];
    final b = <BookChanged>[];
    events.stream.listen(a.add);
    events.stream.listen(b.add);

    events.publish(const BookChanged(42, BookChange.readStatus));
    await pumpEventQueue();

    expect(a.single.bookId, 42);
    expect(b.single.change, BookChange.readStatus);
    await events.dispose();
  });

  test('late subscribers do not get old events', () async {
    final events = LibraryEvents();
    events.publish(const BookChanged(1, BookChange.deleted));
    final late = <BookChanged>[];
    events.stream.listen(late.add);
    await pumpEventQueue();

    expect(late, isEmpty);
    await events.dispose();
  });
}
