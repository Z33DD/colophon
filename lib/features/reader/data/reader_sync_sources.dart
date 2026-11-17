import 'dart:convert';
import 'dart:typed_data';

import 'package:calibre_web_companion/core/services/kosync_service.dart';
import 'package:calibre_web_companion/core/services/webdav_sync_service.dart';
import 'package:calibre_web_companion/features/reader/data/reader_session.dart';
import 'package:cosmos_epub/Helpers/reader_position.dart';
import 'package:cosmos_epub/show_epub.dart' as cosmos_reader;
import 'package:shared_preferences/shared_preferences.dart';

/// The EPUB reader's GetStorage record. `CosmosEpub.initialize` must have
/// run, which `main` does before the first frame.
class CosmosPositionStore implements EpubPositionStore {
  const CosmosPositionStore();

  @override
  ReaderPosition read(String uuid) =>
      cosmos_reader.bookProgress.getPosition(uuid);

  @override
  Future<void> write(String uuid, ReaderPosition position) =>
      cosmos_reader.bookProgress.setPosition(uuid, position);
}

/// Positions in the user's WebDAV folder, configured in Settings.
///
/// The locator is the stored [ReaderPosition] as JSON: `{chapter, page}`
/// from older installs, plus `fraction` from this one. Older installs
/// ignore the extra key, and their records restore through the same
/// migration as local ones.
class WebDavPositionSync implements CloudPositionSync {
  WebDavPositionSync({required this.prefs, required this.service});

  final SharedPreferences prefs;
  final WebDavSyncService service;

  /// Applies the current settings; false when WebDAV is off or unset.
  bool _configure() {
    if (!(prefs.getBool('webdav_enabled') ?? false)) return false;
    final url = prefs.getString('webdav_url') ?? '';
    if (url.isEmpty) return false;
    service.init(
      url,
      prefs.getString('webdav_username') ?? '',
      prefs.getString('webdav_password') ?? '',
      allowSelfSigned: prefs.getBool('allow_self_signed') ?? false,
    );
    return true;
  }

  @override
  Future<CloudPosition?> fetch(String uuid) async {
    if (!_configure()) return null;
    final entry = (await service.fetchProgress())[uuid];
    if (entry is! Map) return null;
    final locator = entry['locator'];
    if (locator is! String) return null;
    final decoded = jsonDecode(locator);
    if (decoded is! Map) return null;
    return CloudPosition(
      ReaderPosition.fromStored(decoded),
      (entry['timestamp'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<bool> save(String uuid, ReaderPosition position, int timestamp) async {
    if (!_configure()) return false;
    await service.saveProgress(
      uuid,
      jsonEncode(position.toStored()),
      timestamp,
    );
    return true;
  }
}

/// KOReader sync through Calibre-Web's kosync endpoint.
class KoSyncProgressSync implements RemoteProgressSync {
  KoSyncProgressSync(this.service);

  final KoSyncService service;

  @override
  Future<KoSyncProgress?> fetch({
    required Uint8List bytes,
    required int id,
  }) async {
    if (!await service.isEnabled()) return null;
    // KOReader names a document by its partial MD5; the Calibre id is the
    // fallback this server's own pushes use.
    return service.fetchProgress(
      document: KoSyncService.partialMd5(bytes),
      fallbackDocument: id > 0 ? id.toString() : null,
    );
  }

  @override
  Future<bool> push({
    required int id,
    required double percentage,
    required int spineIndex,
  }) async {
    if (id <= 0 || !await service.isEnabled()) return false;
    return service.pushProgress(
      bookId: id,
      percentage: percentage,
      spineIndex: spineIndex,
    );
  }
}
