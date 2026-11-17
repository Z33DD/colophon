import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_details/presentation/book_folder.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/ui/action_bar.dart';
import 'package:calibre_web_companion/shared/widgets/app_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadToDeviceWidget extends StatelessWidget {
  final BookDetailsModel book;
  final bool isLoading;

  /// Draws the button (e.g. as an action-bar tile); defaults to an icon.
  final BarActionBuilder? builder;

  const DownloadToDeviceWidget({
    super.key,
    required this.book,
    required this.isLoading,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocConsumer<BookDetailsBloc, BookDetailsState>(
      listenWhen:
          (previous, current) =>
              previous.downloadState != current.downloadState &&
              (current.downloadState == DownloadState.success ||
                  current.downloadState == DownloadState.failed),
      listener:
          (context, state) => reportDownloadResult(
            context,
            state,
            book,
            () => _showDownloadOptions(context, localizations, book),
          ),
      buildWhen:
          (previous, current) =>
              previous.downloadState != current.downloadState ||
              previous.downloadProgress != current.downloadProgress ||
              previous.isDownloaded != current.isDownloaded,
      builder: (context, state) {
        final isDownloaded = state.isDownloaded;
        final downloading = state.downloadState == DownloadState.downloading;
        void onPressed() {
          if (isDownloaded && book.formats.length == 1) {
            context.showSnackBar(localizations.bookAlreadyDownloaded);
          } else {
            _showDownloadOptions(context, localizations, book);
          }
        }

        if (builder != null) {
          return builder!(
            context,
            BarAction(
              icon:
                  isDownloaded
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
              label: localizations.download,
              onPressed: isLoading ? null : onPressed,
              progress:
                  downloading
                      ? (state.downloadProgress > 0
                          ? state.downloadProgress / 100
                          : -1)
                      : null,
              onCancel:
                  () => context.read<BookDetailsBloc>().add(CancelDownload()),
              cancelLabel: localizations.cancelDownload,
            ),
          );
        }

        return IconButton(
          icon: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child:
                state.downloadState == DownloadState.downloading
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value:
                            state.downloadProgress > 0
                                ? state.downloadProgress / 100
                                : null,
                      ),
                    )
                    : Icon(
                      isDownloaded
                          ? Icons.download_done_rounded
                          : Icons.download_rounded,
                    ),
          ),
          onPressed:
              isLoading || state.downloadState == DownloadState.downloading
                  ? null
                  : () {
                    if (isDownloaded && book.formats.length == 1) {
                      context.showSnackBar(localizations.bookAlreadyDownloaded);
                    } else {
                      _showDownloadOptions(context, localizations, book);
                    }
                  },
          tooltip:
              isDownloaded
                  ? localizations.bookAlreadyDownloaded
                  : localizations.downloadToDevice,
        );
      },
    );
  }

  void _showDownloadOptions(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsModel book,
  ) {
    if (book.formats.length == 1) {
      _downloadBook(
        context,
        localizations,
        book,
        book.formats.first.toLowerCase(),
      );
      return;
    }

    final downloadedFormats = context
        .read<BookDetailsBloc>()
        .downloadManager
        .downloadedFormats(book.uuid);

    showAppOptionsSheet(
      context,
      title: localizations.downlaodFomat,
      options: [
        for (final format in book.formats)
          AppSheetOption(
            icon: _formatIcon(format),
            title: format.toUpperCase(),
            subtitle:
                downloadedFormats.contains(format.toLowerCase())
                    ? localizations.bookAlreadyDownloaded
                    : null,
            trailing:
                downloadedFormats.contains(format.toLowerCase())
                    ? Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                    : null,
            onTap: () => _downloadBook(context, localizations, book, format),
          ),
      ],
    );
  }

  IconData _formatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'epub':
        return Icons.menu_book;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'mobi':
        return Icons.book_online;
      default:
        return Icons.file_present;
    }
  }

  Future<void> _downloadBook(
    BuildContext context,
    AppLocalizations localizations,
    BookDetailsModel book,
    String format,
  ) async {
    final settingsState = context.read<SettingsBloc>().state;
    final bloc = context.read<BookDetailsBloc>();
    final target = await pickBookFolder(context);
    if (!target.proceed) return;

    // Progress shows on the button; the result arrives as a snackbar.
    bloc.add(
      DownloadBook(
        bookId: book.id.toString(),
        format: format,
        title: book.title,
        author: book.authors,
        series: book.series,
        seriesIndex: book.seriesIndex,
        directory: target.folder,
        schema: settingsState.downloadSchema,
        pathTemplate: settingsState.downloadPathTemplate,
      ),
    );
  }
}

/// Reports a finished download once, with Open on success and Retry on
/// failure. A cancel needs no message: the user asked for it.
void reportDownloadResult(
  BuildContext context,
  BookDetailsState state,
  BookDetailsModel book,
  VoidCallback retry,
) {
  final l10n = AppLocalizations.of(context)!;
  final bloc = context.read<BookDetailsBloc>();
  switch (state.downloadState) {
    case DownloadState.success:
      final path = state.downloadFilePath;
      context.showSnackBar(
        l10n.downloadedBook(book.title),
        actionLabel: path == null ? null : l10n.open,
        onAction:
            path == null
                ? null
                : () => bloc.repository.openLocalFileExternally(
                  path,
                  format: path.split('.').last.toLowerCase(),
                ),
      );
    case DownloadState.failed:
      context.showSnackBar(
        l10n.downloadFailedTitle(book.title),
        isError: true,
        actionLabel: l10n.retry,
        onAction: retry,
      );
    default:
      break;
  }
}
