import 'package:calibre_web_companion/core/services/download_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('registering and removing a download notifies listeners', () async {
    // Regression: On device built its list once and stayed alive in the
    // navigation stack, so new downloads never appeared there.
    SharedPreferences.setMockInitialValues({});
    final manager = DownloadManager(
      prefs: await SharedPreferences.getInstance(),
      logger: Logger(level: Level.off),
    );
    var notified = 0;
    manager.changes.listen((_) => notified++);

    await manager.registerDownload('u1', '/books/dune.epub');
    await manager.unregisterDownload('u1');
    await pumpEventQueue();

    expect(notified, 2);
  });
}
