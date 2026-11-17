import 'dart:typed_data';

import 'package:calibre_web_companion/core/services/kosync_service.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/reader/data/epub_bookmark_source.dart';
import 'package:calibre_web_companion/features/reader/data/internal_reader_formats.dart';
import 'package:calibre_web_companion/features/reader/data/reader_session.dart';
import 'package:calibre_web_companion/features/reader/presentation/page_reader_launcher.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:cosmos_epub/cosmos_epub.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Opens [bytes] in the in-app reader for [book.format] and runs the whole
/// [ReaderSession]: restore, offer a KOReader jump, track, record and sync.
///
/// Book details and On device both open books through here, so a book
/// keeps its place and progress whichever screen it was opened from.
/// Returns the percentage recorded on close (0-100), or null when the book
/// could not be opened or reported nothing.
Future<double?> openInReader(
  BuildContext context, {
  required ReaderBook book,
  required Uint8List bytes,
  ReaderSession? session,
}) async {
  final readerSession = session ?? GetIt.instance<ReaderSession>();
  final localizations = AppLocalizations.of(context)!;
  final format = book.format.toLowerCase();

  void showOpenError([Object? error]) {
    if (!context.mounted) return;
    context.showSnackBar(
      error == null
          ? localizations.errorOpeningBookInInternalReader
          : '${localizations.errorOpeningBookInInternalReader} $error',
      isError: true,
    );
  }

  if (!InternalReaderFormats.bytesMatch(format, bytes)) {
    showOpenError();
    return null;
  }

  if (InternalReaderFormats.isPageBased(format)) {
    final tracker = readerSession.start(book, syncs: false);
    final percentage = await openPageReader(
      context,
      bytes: bytes,
      format: format,
      bookUuid: book.uuid,
      title: book.title,
      onPageChanged: tracker.onPageFlip,
    );
    return tracker.finish(percentage: percentage);
  }

  await readerSession.restoreFromCloud(book.uuid);
  if (!context.mounted) return null;

  double? startPercentage;
  final offer = await readerSession.remoteOffer(book, bytes);
  if (offer != null && context.mounted) {
    final follow = await _askToFollow(context, offer);
    // Settled either way: declining once must not ask again next open.
    await readerSession.markOfferHandled(book.uuid, offer);
    if (follow) startPercentage = offer.percentage;
  }
  if (!context.mounted) return null;

  final tracker = readerSession.start(
    book,
    syncs: true,
    startPercentage: startPercentage,
  );
  try {
    await CosmosEpub.openFileBook(
      context: context,
      bytes: bytes,
      bookId: book.uuid,
      startPercentage: startPercentage,
      accentColor: Theme.of(context).colorScheme.primary,
      bookmarkSource: StoreEpubBookmarkSource.forBook(book.uuid),
      bookmarkLabels: epubBookmarkLabels(localizations),
      onPageFlip: tracker.onPageFlip,
      onProgressChanged: tracker.onProgressChanged,
    );
  } catch (e) {
    tracker.cancel();
    showOpenError(e);
    return null;
  }
  return tracker.finish();
}

/// Offers to continue where another device left off.
Future<bool> _askToFollow(BuildContext context, KoSyncProgress offer) async {
  final localizations = AppLocalizations.of(context)!;
  final percentage = offer.percentage.toStringAsFixed(0);
  final device = offer.device;
  final follow = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(localizations.koSyncContinueTitle),
          content: Text(
            device == null || device.isEmpty
                ? localizations.koSyncContinueBodyUnknownDevice(percentage)
                : localizations.koSyncContinueBody(device, percentage),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(localizations.koSyncStayHere),
            ),
            AppDialogButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              label: localizations.koSyncJumpThere,
            ),
          ],
        ),
  );
  return follow == true;
}
