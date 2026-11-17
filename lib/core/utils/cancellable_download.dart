import 'dart:async';
import 'dart:io';

import 'package:calibre_web_companion/core/exceptions/cancellation_exception.dart';

/// Lets the UI stop a running book download.
///
/// One token belongs to one download. Cancelling detaches the HTTP body
/// stream, which closes the connection, so no more bytes are transferred.
class DownloadCancelToken {
  bool _cancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  void _onCancel(void Function() listener) => _listeners.add(listener);

  void _remove(void Function() listener) => _listeners.remove(listener);

  void throwIfCancelled() {
    if (_cancelled) throw const CancellationException('Download cancelled');
  }
}

/// Streams [body] into [file] and returns the number of bytes written.
///
/// [onProgress] gets whole percentages (0-100) when [contentLength] is known.
/// On cancel or any error the partial [file] is deleted before the error
/// propagates, so callers never register a truncated book as downloaded.
/// Cancellation surfaces as [CancellationException].
Future<int> writeStreamToFile(
  Stream<List<int>> body,
  File file, {
  required int contentLength,
  void Function(int percent)? onProgress,
  DownloadCancelToken? cancelToken,
}) async {
  cancelToken?.throwIfCancelled();

  final sink = file.openWrite();
  final done = Completer<int>();
  var received = 0;
  late final StreamSubscription<List<int>> subscription;

  void onCancel() {
    if (done.isCompleted) return;
    unawaited(subscription.cancel());
    done.completeError(const CancellationException('Download cancelled'));
  }

  subscription = body.listen(
    (chunk) {
      sink.add(chunk);
      received += chunk.length;
      if (contentLength > 0 && onProgress != null) {
        onProgress((received / contentLength * 100).round());
      }
    },
    onError: (Object error, StackTrace stack) {
      if (!done.isCompleted) done.completeError(error, stack);
      unawaited(subscription.cancel());
    },
    onDone: () {
      if (!done.isCompleted) done.complete(received);
    },
    cancelOnError: true,
  );
  cancelToken?._onCancel(onCancel);

  try {
    final bytes = await done.future;
    await sink.flush();
    return bytes;
  } catch (_) {
    await sink.close().catchError((_) {});
    if (file.existsSync()) await file.delete();
    rethrow;
  } finally {
    cancelToken?._remove(onCancel);
    // Safe to call twice; the error path already closed it.
    await sink.close().catchError((_) {});
  }
}
