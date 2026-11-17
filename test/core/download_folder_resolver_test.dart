import 'package:calibre_web_companion/core/services/download_folder_resolver.dart';
import 'package:docman/docman.dart';
import 'package:flutter_test/flutter_test.dart';

const _folder = DocumentFile(uri: 'content://tree/books', type: 'directory');
const _file = DocumentFile(uri: 'content://tree/a.epub', type: 'file');

void main() {
  group('DownloadFolderResolver', () {
    test('cancelled picker is reported as a cancel, not as a folder', () async {
      // Regression: "Open in reader" used to pop book details on this path.
      final resolver = DownloadFolderResolver(
        isAndroid: true,
        pickDirectory: () async => null,
        fromUri: (_) async => fail('must not reopen a stored folder'),
      );

      expect(
        await resolver.resolve(defaultFolderUri: ''),
        isA<FolderPickCancelled>(),
      );
    });

    test('picked folder is returned when no default is set', () async {
      final resolver = DownloadFolderResolver(
        isAndroid: true,
        pickDirectory: () async => _folder,
      );

      final result = await resolver.resolve(defaultFolderUri: '');

      expect((result as FolderResolved).folder, _folder);
    });

    test('stored default folder is reused without asking', () async {
      final resolver = DownloadFolderResolver(
        isAndroid: true,
        pickDirectory: () async => fail('must not ask when a default exists'),
        fromUri: (uri) async => uri == _folder.uri ? _folder : null,
      );

      final result = await resolver.resolve(defaultFolderUri: _folder.uri);

      expect((result as FolderResolved).folder, _folder);
    });

    test(
      'a stored default that is gone or not a folder is unavailable',
      () async {
        final gone = DownloadFolderResolver(
          isAndroid: true,
          fromUri: (_) async => null,
        );
        final notDir = DownloadFolderResolver(
          isAndroid: true,
          fromUri: (_) async => _file,
        );

        expect(
          await gone.resolve(defaultFolderUri: 'x'),
          isA<FolderUnavailable>(),
        );
        expect(
          await notDir.resolve(defaultFolderUri: 'x'),
          isA<FolderUnavailable>(),
        );
      },
    );

    test('non-Android platforms need no folder', () async {
      final resolver = DownloadFolderResolver(
        isAndroid: false,
        pickDirectory: () async => fail('must not ask off Android'),
      );

      final result = await resolver.resolve(defaultFolderUri: '');

      expect((result as FolderResolved).folder, isNull);
    });
  });
}
