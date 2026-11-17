import 'dart:io';

import 'package:docman/docman.dart';

/// Outcome of resolving where a book file should be written on Android.
sealed class FolderResolution {
  const FolderResolution();
}

/// Use this folder. `folder` is null on platforms that do not need a
/// Storage Access Framework folder (everything except Android).
final class FolderResolved extends FolderResolution {
  const FolderResolved(this.folder);
  final DocumentFile? folder;
}

/// The user dismissed the folder picker. Callers must stay on the current
/// screen: this is a normal choice, not an error, and must never pop a route.
final class FolderPickCancelled extends FolderResolution {
  const FolderPickCancelled();
}

/// A default folder is configured but no longer exists or is not a folder
/// (for example, the user revoked the SAF permission or deleted it).
final class FolderUnavailable extends FolderResolution {
  const FolderUnavailable();
}

/// Single place that decides which folder a download or "open in reader"
/// uses. Previously this logic was copied into several widgets, and one copy
/// popped the book details page when the picker was cancelled.
class DownloadFolderResolver {
  DownloadFolderResolver({
    bool? isAndroid,
    Future<DocumentFile?> Function()? pickDirectory,
    Future<DocumentFile?> Function(String uri)? fromUri,
  }) : _isAndroid = isAndroid ?? Platform.isAndroid,
       _pickDirectory = pickDirectory ?? DocMan.pick.directory,
       _fromUri = fromUri ?? DocumentFile.fromUri;

  final bool _isAndroid;
  final Future<DocumentFile?> Function() _pickDirectory;
  final Future<DocumentFile?> Function(String uri) _fromUri;

  /// Resolves the target folder. With an empty [defaultFolderUri] the user
  /// is asked to pick one; otherwise the stored SAF URI is reopened.
  Future<FolderResolution> resolve({required String defaultFolderUri}) async {
    if (!_isAndroid) return const FolderResolved(null);

    if (defaultFolderUri.isEmpty) {
      final picked = await _pickDirectory();
      return picked == null
          ? const FolderPickCancelled()
          : FolderResolved(picked);
    }

    final folder = await _fromUri(defaultFolderUri);
    if (folder == null || !folder.isDirectory) {
      return const FolderUnavailable();
    }
    return FolderResolved(folder);
  }
}
