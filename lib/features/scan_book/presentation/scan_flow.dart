import 'dart:async';

import 'package:calibre_web_companion/core/navigation/app_route.dart';
import 'package:calibre_web_companion/features/scan_book/data/datasources/isbn_remote_datasource.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/isbn_lookup_result.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/pages/isbn_sources_page.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/widgets/scan_result_sheet.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger();

Future<bool> isDownloaderConfigured() async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getString('downloader_url') ?? '').isNotEmpty;
}

Future<String?> promptForIsbn(BuildContext context, {String? initial}) {
  final localizations = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(localizations.enterIsbn),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: localizations.isbn,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.numbers_rounded),
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(localizations.cancel),
          ),
          AppDialogButton(
            label: localizations.search,
            icon: Icons.search,
            onPressed:
                () => Navigator.of(dialogContext).pop(controller.text.trim()),
          ),
        ],
      );
    },
  );
}

Future<bool> runIsbnLookupFlow(BuildContext context, String isbn) async {
  final source = IsbnRemoteDataSource();
  var currentIsbn = isbn;

  while (true) {
    if (!context.mounted) return false;
    final result = await _lookupWithProgress(context, source, currentIsbn);
    if (!context.mounted) return false;

    switch (result) {
      case IsbnLookupFound(:final book):
        final downloaderConfigured = await isDownloaderConfigured();
        if (!context.mounted) return false;
        final added = await showScanResultSheet(
          context,
          book: book,
          downloaderConfigured: downloaderConfigured,
        );
        return added == true;
      case IsbnLookupFailed():
        // One message with Retry; never also claim the ISBN does not exist.
        if (!await _lookupFailedDialog(context)) return false;
      case IsbnLookupNotFound():
        final retryIsbn = await _notFoundDialog(context, currentIsbn);
        if (retryIsbn == null || retryIsbn.isEmpty) return false;
        currentIsbn = retryIsbn;
    }
  }
}

enum _NotFoundAction { cancel, editIsbn, metadataSources }

Future<IsbnLookupResult> _lookupWithProgress(
  BuildContext context,
  IsbnRemoteDataSource source,
  String isbn,
) async {
  final localizations = AppLocalizations.of(context)!;
  _logger.i('Manual ISBN flow: looking up $isbn');

  unawaited(
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 20),
                  Flexible(child: Text(localizations.lookingUpBook)),
                ],
              ),
            ),
          ),
    ),
  );

  final result = await classifyIsbnLookup(source.lookupByIsbn, isbn);
  if (result case IsbnLookupFailed(:final error)) {
    _logger.e('Manual ISBN lookup failed for $isbn: $error');
  }

  if (context.mounted) {
    Navigator.of(context).pop();
  }
  return result;
}

/// Returns true when the user wants to retry the same ISBN.
Future<bool> _lookupFailedDialog(BuildContext context) async {
  final localizations = AppLocalizations.of(context)!;
  final retry = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(localizations.isbnLookupFailed),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(localizations.cancel),
            ),
            AppDialogButton(
              label: localizations.retry,
              icon: Icons.refresh_rounded,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
  );
  return retry == true;
}

Future<String?> _notFoundDialog(BuildContext context, String isbn) async {
  final localizations = AppLocalizations.of(context)!;
  final action = await showDialog<_NotFoundAction>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(localizations.isbnNotFound),
        content: Text('ISBN: $isbn'),
        actions: [
          TextButton(
            onPressed:
                () => Navigator.of(dialogContext).pop(_NotFoundAction.cancel),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed:
                () => Navigator.of(
                  dialogContext,
                ).pop(_NotFoundAction.metadataSources),
            child: Text(localizations.isbnTryMoreSources),
          ),
          AppDialogButton(
            label: localizations.editIsbn,
            icon: Icons.edit_rounded,
            onPressed:
                () => Navigator.of(dialogContext).pop(_NotFoundAction.editIsbn),
          ),
        ],
      );
    },
  );

  if (!context.mounted) return null;

  switch (action) {
    case _NotFoundAction.editIsbn:
      return promptForIsbn(context, initial: isbn);
    case _NotFoundAction.metadataSources:
      await Navigator.of(context).push(AppRoute.page(const IsbnSourcesPage()));
      return isbn;
    case _NotFoundAction.cancel:
    case null:
      return null;
  }
}
