import 'dart:typed_data';

import 'package:calibre_web_companion/core/services/kosync_service.dart';
import 'package:calibre_web_companion/core/services/library_events.dart';
import 'package:calibre_web_companion/core/services/reading_progress_index.dart';
import 'package:calibre_web_companion/features/reader/data/reader_session.dart';
import 'package:cosmos_epub/Helpers/reader_position.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePositions implements EpubPositionStore {
  final Map<String, ReaderPosition> saved = {};
  @override
  ReaderPosition read(String uuid) =>
      saved[uuid] ?? const ReaderPosition(chapter: 0);
  @override
  Future<void> write(String uuid, ReaderPosition position) async =>
      saved[uuid] = position;
}

class FakeCloud implements CloudPositionSync {
  CloudPosition? remote;
  bool enabled = true;
  final List<ReaderPosition> saves = [];
  @override
  Future<CloudPosition?> fetch(String uuid) async => enabled ? remote : null;
  @override
  Future<bool> save(String uuid, ReaderPosition position, int ts) async {
    if (!enabled) return false;
    saves.add(position);
    return true;
  }
}

class FakeRemote implements RemoteProgressSync {
  KoSyncProgress? remote;
  final List<double> pushes = [];
  @override
  Future<KoSyncProgress?> fetch({
    required Uint8List bytes,
    required int id,
  }) async => remote;
  @override
  Future<bool> push({
    required int id,
    required double percentage,
    required int spineIndex,
  }) async {
    pushes.add(percentage);
    return true;
  }
}

void main() {
  late SharedPreferences prefs;
  late FakePositions positions;
  late FakeCloud cloud;
  late FakeRemote remote;
  late LibraryEvents events;
  late ReaderSession session;
  final widgetUpdates = <double>[];

  const book = ReaderBook(uuid: 'u1', id: 7, title: 'T', format: 'epub');
  const sideloaded = ReaderBook(uuid: 'u2', id: 0, title: 'T', format: 'epub');
  final bytes = Uint8List.fromList([0x50, 0x4B, 3, 4]);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    positions = FakePositions();
    cloud = FakeCloud();
    remote = FakeRemote();
    events = LibraryEvents();
    widgetUpdates.clear();
    session = ReaderSession(
      prefs: prefs,
      progressIndex: ReadingProgressIndex(prefs),
      events: events,
      positions: positions,
      cloud: cloud,
      remote: remote,
      onWidgetProgress: (_, progress) => widgetUpdates.add(progress),
      syncDelay: const Duration(milliseconds: 10),
      clock: () => 1000,
    );
  });

  group('restore', () {
    test('a newer WebDAV position replaces the local one', () async {
      cloud.remote = const CloudPosition(
        ReaderPosition(chapter: 4, page: 2, fraction: 0.5),
        900,
      );
      await session.restoreFromCloud('u1');
      expect(positions.read('u1').chapter, 4);
      expect(positions.read('u1').fraction, 0.5);
    });

    test('an older WebDAV position is ignored', () async {
      await prefs.setInt(ReaderSession.localTimestampKey('u1'), 950);
      positions.saved['u1'] = const ReaderPosition(chapter: 1);
      cloud.remote = const CloudPosition(ReaderPosition(chapter: 4), 900);
      await session.restoreFromCloud('u1');
      expect(positions.read('u1').chapter, 1);
    });

    test('WebDAV off leaves the local position alone', () async {
      cloud.enabled = false;
      positions.saved['u1'] = const ReaderPosition(chapter: 1);
      await session.restoreFromCloud('u1');
      expect(positions.read('u1').chapter, 1);
    });
  });

  group('KOReader offer', () {
    test('offers a new remote position once, answered either way', () async {
      remote.remote = const KoSyncProgress(document: 'd', percentage: 40);
      final offer = await session.remoteOffer(book, bytes);
      expect(offer?.percentage, 40);
      await session.markOfferHandled('u1', offer!);
      expect(await session.remoteOffer(book, bytes), isNull);
    });

    test('a remote position at 0% is not offered', () async {
      remote.remote = const KoSyncProgress(document: 'd', percentage: 0);
      expect(await session.remoteOffer(book, bytes), isNull);
    });
  });

  group('finish', () {
    test(
      'records progress, saves to WebDAV, pushes and tells the library',
      () async {
        final seen = <BookChanged>[];
        final sub = events.stream.listen(seen.add);
        positions.saved['u1'] = const ReaderPosition(
          chapter: 2,
          page: 3,
          fraction: 0.3,
        );

        final tracker = session.start(book, syncs: true);
        tracker.onPageFlip(3, 10);
        tracker.onProgressChanged(42, 5);
        expect(await tracker.finish(), 42);
        await Future<void>.delayed(Duration.zero);

        expect(ReadingProgressIndex(prefs).percentFor('u1'), 42);
        expect(cloud.saves.single.fraction, 0.3);
        expect(remote.pushes, [42]);
        expect(seen.single.change, BookChange.progress);
        expect(widgetUpdates, [0.4]);
        // Our own push must not come back as an offer next time.
        remote.remote = const KoSyncProgress(document: 'd', percentage: 42);
        expect(await session.remoteOffer(book, bytes), isNull);
        await sub.cancel();
      },
    );

    test('closing at the jumped-to position does not push it back', () async {
      final tracker = session.start(book, syncs: true, startPercentage: 40);
      tracker.onProgressChanged(40.05, 1);
      await tracker.finish();
      expect(remote.pushes, isEmpty);
    });

    test(
      'page readers record their closing percentage and do not sync',
      () async {
        final tracker = session.start(
          const ReaderBook(uuid: 'u1', id: 7, title: 'T', format: 'pdf'),
          syncs: false,
        );
        expect(await tracker.finish(percentage: 63), 63);
        expect(ReadingProgressIndex(prefs).percentFor('u1'), 63);
        expect(cloud.saves, isEmpty);
        expect(remote.pushes, isEmpty);
      },
    );

    test('a book without a Calibre id records but skips KOReader', () async {
      // Regression: On device opened books without recording progress.
      final seen = <BookChanged>[];
      final sub = events.stream.listen(seen.add);
      final tracker = session.start(sideloaded, syncs: true);
      tracker.onProgressChanged(10, 0);
      await tracker.finish();
      await Future<void>.delayed(Duration.zero);
      expect(ReadingProgressIndex(prefs).percentFor('u2'), 10);
      expect(remote.pushes, isEmpty);
      expect(seen, isEmpty);
      await sub.cancel();
    });

    test('page turns sync after a quiet period', () async {
      final tracker = session.start(book, syncs: true);
      tracker.onProgressChanged(20, 1);
      tracker.onPageFlip(1, 10);
      tracker.onPageFlip(2, 10);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(remote.pushes, [20]);
      expect(cloud.saves, hasLength(1));
      tracker.cancel();
    });

    test('a cancelled read records nothing', () async {
      final tracker = session.start(book, syncs: true);
      tracker.onProgressChanged(20, 1);
      tracker.cancel();
      expect(await tracker.finish(), isNull);
      expect(ReadingProgressIndex(prefs).percentFor('u1'), isNull);
    });
  });
}
