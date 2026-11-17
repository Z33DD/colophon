import 'package:calibre_web_companion/core/services/download_folder_resolver.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Result of [pickBookFolder]: go ahead with [folder] (null off Android),
/// or stop because the user cancelled or the folder is gone.
typedef BookFolder = ({bool proceed, DocumentFile? folder});

/// The one folder step for download, open-in-reader and send.
///
/// With a default folder set it is reused silently. Otherwise the user
/// picks one, and a snackbar offers to keep it as the default so the
/// picker doesn't come back every time. A cancelled picker is a choice,
/// not an error: no message, and the caller stays on its screen.
Future<BookFolder> pickBookFolder(
  BuildContext context, {
  DownloadFolderResolver? resolver,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final settings = context.read<SettingsBloc>();
  final hadDefault = settings.state.defaultDownloadPath.isNotEmpty;

  final result = await (resolver ?? DownloadFolderResolver()).resolve(
    defaultFolderUri: settings.state.defaultDownloadPath,
  );
  if (!context.mounted) return (proceed: false, folder: null);

  switch (result) {
    case FolderResolved(:final folder):
      if (folder != null && !hadDefault) {
        context.showSnackBar(
          l10n.folderSavedHere(folder.name),
          actionLabel: l10n.folderAlwaysUse,
          onAction: () => settings.add(SetDownloadFolder(folder.uri)),
        );
      }
      return (proceed: true, folder: folder);
    case FolderPickCancelled():
      return (proceed: false, folder: null);
    case FolderUnavailable():
      context.showSnackBar(l10n.folderUnavailable, isError: true);
      return (proceed: false, folder: null);
  }
}
