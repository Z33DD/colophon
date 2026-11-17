import 'dart:async';
import 'dart:typed_data';

import 'package:calibre_web_companion/core/services/kosync_service.dart';
import 'package:calibre_web_companion/core/services/library_events.dart';
import 'package:calibre_web_companion/core/services/reading_progress_index.dart';
import 'package:cosmos_epub/Helpers/reader_position.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The book a reading session is for.
class ReaderBook {
  const ReaderBook({
    required this.uuid,
    required this.id,
    required this.title,
    required this.format,
  });

  final String uuid;

  /// Calibre id, or 0 for a file on the device the server does not know.
  /// KOReader sync and library events need a real id and are skipped
  /// without one.
  final int id;
  final String title;
  final String format;
}

/// The EPUB reader's own saved position on this device.
abstract class EpubPositionStore {
  ReaderPosition read(String uuid);
  Future<void> write(String uuid, ReaderPosition position);
}

/// A position saved to the user's WebDAV folder, with when it was saved.
class CloudPosition {
  const CloudPosition(this.position, this.timestamp);
  final ReaderPosition position;

  /// Milliseconds since the epoch.
  final int timestamp;
}

/// Exact positions shared between this app's installs (WebDAV).
///
/// Implementations return null or false when the source is turned off or
/// unreachable: sync is best effort and never blocks reading.
abstract class CloudPositionSync {
  Future<CloudPosition?> fetch(String uuid);
  Future<bool> save(String uuid, ReaderPosition position, int timestamp);
}

/// Whole-book percentages shared with KOReader devices.
///
/// Same contract as [CloudPositionSync]: null or false when off or failing.
abstract class RemoteProgressSync {
  Future<KoSyncProgress?> fetch({required Uint8List bytes, required int id});
  Future<bool> push({
    required int id,
    required double percentage,
    required int spineIndex,
  });
}

/// Opening, restoring, recording and syncing reading progress, the same way
/// for every entry point (book details, On device).
///
/// The flow for one read:
/// 1. [restoreFromCloud] pulls a newer WebDAV position into the local store.
/// 2. [remoteOffer] returns a KOReader position worth offering to jump to;
///    the caller asks the user and reports the answer to [markOfferHandled].
/// 3. [start] returns a [ReadingTracker] that the reader feeds while open.
/// 4. [ReadingTracker.finish] records the percentage for covers and "Continue
///    · 64%", saves to WebDAV, pushes to KOReader and tells the library.
class ReaderSession {
  ReaderSession({
    required this.prefs,
    required this.progressIndex,
    required this.events,
    required this.positions,
    required this.cloud,
    required this.remote,
    this.onWidgetProgress,
    this.syncDelay = const Duration(seconds: 5),
    int Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SharedPreferences prefs;
  final ReadingProgressIndex progressIndex;
  final LibraryEvents events;
  final EpubPositionStore positions;
  final CloudPositionSync cloud;
  final RemoteProgressSync remote;

  /// Home screen widget progress, 0-1. Optional so tests can omit it.
  final void Function(String uuid, double progress)? onWidgetProgress;

  /// Quiet time after a page turn before syncing, so reading does not send
  /// a request per page.
  final Duration syncDelay;
  final int Function() _clock;

  static String localTimestampKey(String uuid) => 'reader_progress_ts_$uuid';
  static String appliedOfferKey(String uuid) => 'kosync_applied_$uuid';

  /// Replaces the local position with the WebDAV one when that is newer.
  Future<void> restoreFromCloud(String uuid) async {
    final CloudPosition? saved;
    try {
      saved = await cloud.fetch(uuid);
    } catch (_) {
      return;
    }
    if (saved == null) return;
    final localTs = prefs.getInt(localTimestampKey(uuid)) ?? 0;
    if (saved.timestamp <= localTs) return;
    await positions.write(uuid, saved.position);
    await prefs.setInt(localTimestampKey(uuid), saved.timestamp);
  }

  /// A KOReader position to offer, or null when there is none or it was
  /// already offered (accepted or declined).
  Future<KoSyncProgress?> remoteOffer(ReaderBook book, Uint8List bytes) async {
    final KoSyncProgress? found;
    try {
      found = await remote.fetch(bytes: bytes, id: book.id);
    } catch (_) {
      return null;
    }
    if (found == null || found.percentage <= 0) return null;

    // Offering the same position twice would ask on every open and undo
    // reading done since, so an offered position is settled.
    final applied = prefs.getDouble(appliedOfferKey(book.uuid));
    if (applied != null && (applied - found.percentage).abs() < 0.5) {
      return null;
    }
    return found;
  }

  /// Remembers that [offer] was answered, either way.
  Future<void> markOfferHandled(String uuid, KoSyncProgress offer) =>
      prefs.setDouble(appliedOfferKey(uuid), offer.percentage);

  /// Begins tracking a read. [syncs] is true for EPUB, the only format
  /// with WebDAV and KOReader positions. [startPercentage] is where the
  /// reader opens, so closing without moving does not push it back.
  ReadingTracker start(
    ReaderBook book, {
    required bool syncs,
    double? startPercentage,
  }) => ReadingTracker._(this, book, syncs, startPercentage);
}

/// One open book. Feed it from the reader's callbacks, then [finish] it.
class ReadingTracker {
  ReadingTracker._(this._session, this.book, this._syncs, this._pushed);

  final ReaderSession _session;
  final ReaderBook book;
  final bool _syncs;

  double? _percentage;
  int _spineIndex = -1;
  double? _pushed;
  int _widgetPercent = -1;
  Timer? _timer;
  bool _finished = false;

  /// Whole-book percentage (0-100) of the last reported position.
  double? get percentage => _percentage;

  /// A page turn. Updates the home widget and schedules a sync.
  void onPageFlip(int page, int pageCount) {
    if (pageCount > 0) {
      final percent = (((page + 1) / pageCount) * 100).round().clamp(0, 100);
      if (percent != _widgetPercent) {
        _widgetPercent = percent;
        _session.onWidgetProgress?.call(book.uuid, percent / 100);
      }
    }
    if (!_syncs || _finished) return;
    _timer?.cancel();
    _timer = Timer(_session.syncDelay, () => unawaited(_sync()));
  }

  /// The EPUB reader's whole-book position after a page turn.
  void onProgressChanged(double percentage, int spineIndex) {
    _percentage = percentage;
    _spineIndex = spineIndex;
  }

  /// Drops pending syncs without recording anything (the reader failed).
  void cancel() {
    _finished = true;
    _timer?.cancel();
  }

  /// Records and syncs the final position. [percentage] overrides the
  /// tracked one for readers that report only when they close (PDF, CBZ).
  /// Returns the percentage recorded, or null when nothing was read.
  Future<double?> finish({double? percentage}) async {
    if (_finished) return null;
    _finished = true;
    _timer?.cancel();
    if (percentage != null) _percentage = percentage;

    final recorded = _percentage;
    if (recorded != null) {
      await _session.progressIndex.record(book.uuid, recorded);
      if (book.id > 0) {
        _session.events.publish(BookChanged(book.id, BookChange.progress));
      }
    }
    if (_syncs) await _sync();
    return recorded;
  }

  Future<void> _sync() async {
    await _saveToCloud();
    await _pushRemote();
  }

  Future<void> _saveToCloud() async {
    final now = _session._clock();
    final position = _session.positions.read(book.uuid);
    try {
      final ok = await _session.cloud.save(book.uuid, position, now);
      if (ok) {
        await _session.prefs.setInt(
          ReaderSession.localTimestampKey(book.uuid),
          now,
        );
      }
    } catch (_) {}
  }

  Future<void> _pushRemote() async {
    final percentage = _percentage;
    if (book.id <= 0 || percentage == null) return;
    final pushed = _pushed;
    if (pushed != null && (pushed - percentage).abs() < 0.1) return;

    final bool ok;
    try {
      ok = await _session.remote.push(
        id: book.id,
        percentage: percentage,
        spineIndex: _spineIndex,
      );
    } catch (_) {
      return;
    }
    if (!ok) return;
    _pushed = percentage;

    // Our own position must not come back as an offer on the next open.
    await _session.prefs.setDouble(
      ReaderSession.appliedOfferKey(book.uuid),
      percentage,
    );
  }
}
