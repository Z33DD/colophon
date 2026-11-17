import 'dart:async';
import 'dart:io';

import 'package:calibre_web_companion/core/exceptions/cancellation_exception.dart';
import 'package:calibre_web_companion/core/utils/cancellable_download.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('cwc_dl_'));
  tearDown(() async => dir.delete(recursive: true));

  group('writeStreamToFile', () {
    test('writes every chunk and reports progress', () async {
      final file = File('${dir.path}/book.epub');
      final progress = <int>[];

      final received = await writeStreamToFile(
        Stream.fromIterable([
          [1, 2],
          [3, 4],
        ]),
        file,
        contentLength: 4,
        onProgress: progress.add,
      );

      expect(received, 4);
      expect(await file.readAsBytes(), [1, 2, 3, 4]);
      expect(progress, [50, 100]);
    });

    test('cancel stops the transfer and removes the partial file', () async {
      // Regression: CancelDownload only changed bloc state, so the transfer
      // kept running and the book was later marked downloaded.
      final file = File('${dir.path}/book.epub');
      final source = StreamController<List<int>>();
      final token = DownloadCancelToken();

      final pending = writeStreamToFile(
        source.stream,
        file,
        contentLength: 100,
        cancelToken: token,
      );

      source.add(List.filled(40, 0));
      await pumpEventQueue();
      token.cancel();

      await expectLater(pending, throwsA(isA<CancellationException>()));
      expect(source.hasListener, isFalse, reason: 'source must be detached');
      expect(file.existsSync(), isFalse);
      await source.close();
    });

    test('an already cancelled token never opens the file', () async {
      final file = File('${dir.path}/book.epub');
      final token = DownloadCancelToken()..cancel();

      await expectLater(
        writeStreamToFile(
          Stream.value([1]),
          file,
          contentLength: 1,
          cancelToken: token,
        ),
        throwsA(isA<CancellationException>()),
      );
      expect(file.existsSync(), isFalse);
    });

    test('a stream error removes the partial file and rethrows', () async {
      final file = File('${dir.path}/book.epub');

      await expectLater(
        writeStreamToFile(
          Stream.fromIterable([
            [1],
          ]).followedByError(const SocketException('reset')),
          file,
          contentLength: 10,
        ),
        throwsA(isA<SocketException>()),
      );
      expect(file.existsSync(), isFalse);
    });
  });
}

extension<T> on Stream<T> {
  Stream<T> followedByError(Exception error) async* {
    yield* this;
    throw error;
  }
}
