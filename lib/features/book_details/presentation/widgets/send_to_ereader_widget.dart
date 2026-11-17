import 'dart:io';

import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/utils/book_drop.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_bloc.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_event.dart';
import 'package:calibre_web_companion/features/book_details/bloc/book_details_state.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_details/data/send_preferences.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/ui/action_bar.dart';
import 'package:calibre_web_companion/shared/widgets/app_dialog_button.dart';
import 'package:docman/docman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendToEreaderWidget extends StatelessWidget {
  final BookDetailsModel book;
  final bool isLoading;

  /// Draws the "Send to e-reader" action in the caller's style.
  final BarActionBuilder builder;

  const SendToEreaderWidget({
    super.key,
    required this.book,
    required this.isLoading,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<BookDetailsBloc, BookDetailsState>(
      builder: (context, bookDetailsState) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            return builder(
              context,
              BarAction(
                icon: Icons.send_rounded,
                label: localizations.sendToEReader,
                onPressed:
                    isLoading
                        ? null
                        : () => _showSendToReaderDialog(context, localizations),
              ),
            );
          },
        );
      },
    );
  }

  void _showSendToReaderDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final parentContext = context;
    final prefs = GetIt.instance<SharedPreferences>();
    final codeController = TextEditingController();
    var choice = SendPreferences.load(prefs);
    var format = choice.formatFor(book.formats);
    final formats = {for (final f in book.formats) f.toLowerCase()}.toList();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final needsCode = choice.method == SendMethod.browser;
              final canSend =
                  !needsCode || codeController.text.trim().length == 4;
              return AlertDialog(
                title: Text(localizations.sendToKindleKobo),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        localizations.sendMethodLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<SendMethod>(
                        segments: [
                          ButtonSegment(
                            value: SendMethod.browser,
                            icon: const Icon(Icons.public_rounded),
                            label: Text(localizations.sendMethodBrowser),
                          ),
                          ButtonSegment(
                            value: SendMethod.email,
                            icon: const Icon(Icons.mail_outline_rounded),
                            label: Text(localizations.sendMethodEmail),
                          ),
                        ],
                        selected: {choice.method},
                        onSelectionChanged:
                            (value) => setState(
                              () =>
                                  choice = SendPreferences(
                                    method: value.single,
                                    kindle: choice.kindle,
                                    format: choice.format,
                                  ),
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (needsCode) ...[
                        Text(
                          localizations.deviceLabel,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(localizations.deviceKobo),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(localizations.deviceKindle),
                            ),
                          ],
                          selected: {choice.kindle},
                          onSelectionChanged:
                              (value) => setState(
                                () =>
                                    choice = SendPreferences(
                                      method: choice.method,
                                      kindle: value.single,
                                      format: choice.format,
                                    ),
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildCodeInput(
                          context,
                          localizations,
                          codeController,
                          onChanged: () => setState(() {}),
                        ),
                      ] else ...[
                        if (formats.length > 1) ...[
                          Text(
                            localizations.sendFormat,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final f in formats)
                                ChoiceChip(
                                  label: Text(f.toUpperCase()),
                                  selected: f == format,
                                  onSelected: (_) => setState(() => format = f),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildEmailInfo(context, localizations),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(localizations.cancel),
                  ),
                  AppDialogButton(
                    // Disabled until the 4-character code is complete.
                    onPressed:
                        canSend
                            ? () {
                              final chosen = SendPreferences(
                                method: choice.method,
                                kindle: choice.kindle,
                                format:
                                    choice.method == SendMethod.email
                                        ? format
                                        : choice.format,
                              );
                              chosen.save(prefs);
                              Navigator.pop(context);
                              if (chosen.method == SendMethod.browser) {
                                _sendToEReaderViaBrowser(
                                  parentContext,
                                  localizations,
                                  codeController.text.trim().toUpperCase(),
                                  chosen.kindle,
                                );
                              } else {
                                _sendToEReaderByEmail(
                                  parentContext,
                                  localizations,
                                  format,
                                );
                              }
                            }
                            : null,
                    label: localizations.send,
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildCodeInput(
    BuildContext context,
    AppLocalizations localizations,
    TextEditingController codeController, {
    VoidCallback? onChanged,
  }) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Column(
          children: [
            Text(localizations.enter4DigitCode),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'XXXX',
                counterText: '',
              ),
              onChanged: (value) {
                codeController.value = codeController.value.copyWith(
                  text: value.toUpperCase(),
                  selection: TextSelection.collapsed(offset: value.length),
                );
                onChanged?.call();
              },
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                text: localizations.visit,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text:
                        ' ${bookDropReceiveUrl(settingsState.send2ereaderUrl)} ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: localizations.onYourEReader),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmailInfo(BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.bookWillBeSendToYourEmailAdress,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            localizations.makeSureEmailSettingsAreConfigured,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: .8),
            ),
          ),
        ],
      ),
    );
  }

  void _sendToEReaderViaBrowser(
    BuildContext context,
    AppLocalizations localizations,
    String code,
    bool isKindle,
  ) async {
    final settingsState = context.read<SettingsBloc>().state;
    DocumentFile? selectedDirectory;

    // "Store on device first" needs a SAF folder, which iOS doesn't have — there
    // the bytes are streamed straight to the upload instead.
    final storeOnDevice =
        Platform.isAndroid &&
        settingsState.storeReadNowAndSendToEReaderOnDevice;

    if (storeOnDevice) {
      final uri = settingsState.defaultDownloadPath;
      if (uri.isEmpty) {
        context.showSnackBar(
          localizations.pleaseSetDefaultDownloadFolderFirst,
          isError: true,
        );
        return;
      }

      selectedDirectory = await DocumentFile.fromUri(uri);
      if (selectedDirectory == null || !selectedDirectory.isDirectory) {
        if (context.mounted) {
          context.showSnackBar(
            localizations.noFolderWasSelected,
            isError: true,
          );
        }
        return;
      }
    }

    if (!context.mounted) {
      return;
    }

    _showTransferStatusDialog(context, localizations);

    context.read<BookDetailsBloc>().add(
      SendToEReaderViaBrowser(
        bookId: book.id.toString(),
        code: code,
        isKindle: isKindle,
        title: book.title,
        send2ereaderUrl: context.read<SettingsBloc>().state.send2ereaderUrl,
        downloadToDeviceFirst: storeOnDevice,
        selectedDirectory: selectedDirectory,
        schema: settingsState.downloadSchema,
        pathTemplate: settingsState.downloadPathTemplate,
      ),
    );
  }

  void _sendToEReaderByEmail(
    BuildContext context,
    AppLocalizations localizations,
    String format,
  ) {
    _showTransferStatusDialog(context, localizations);

    context.read<BookDetailsBloc>().add(
      SendToEReaderByEmail(bookId: book.id.toString(), format: format),
    );
  }

  void _showTransferStatusDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final outerContext = context;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .54),
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: BlocProvider.value(
            value: BlocProvider.of<BookDetailsBloc>(outerContext),
            child: BlocConsumer<BookDetailsBloc, BookDetailsState>(
              listenWhen:
                  (previous, current) =>
                      previous.sendToEReaderState != current.sendToEReaderState,
              listener: (context, state) {
                if (state.sendToEReaderState == SendToEReaderState.success) {
                  outerContext.showSnackBar(
                    localizations.successfullySentToEReader,
                    isError: false,
                  );
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                } else if (state.sendToEReaderState ==
                    SendToEReaderState.error) {
                  outerContext.showSnackBar(
                    state.errorMessage ?? localizations.transferFailed,
                    isError: true,
                  );
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }
              },
              buildWhen:
                  (previous, current) =>
                      previous.sendToEReaderState !=
                          current.sendToEReaderState ||
                      previous.sendToEReaderProgress !=
                          current.sendToEReaderProgress,
              builder: (context, state) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusIcon(state.sendToEReaderState, context),
                        const SizedBox(height: 20),
                        Text(
                          _getStatusMessage(
                            state.sendToEReaderState,
                            localizations,
                          ),
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        if (state.sendToEReaderState ==
                            SendToEReaderState.loading)
                          LinearProgressIndicator(
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),

                        if (state.sendToEReaderState ==
                                SendToEReaderState.downloading ||
                            state.sendToEReaderState ==
                                SendToEReaderState.uploading)
                          Column(
                            children: [
                              LinearProgressIndicator(
                                backgroundColor:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                value:
                                    state.sendToEReaderProgress > 0
                                        ? state.sendToEReaderProgress / 100
                                        : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${state.sendToEReaderProgress}%',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),

                        if (state.errorMessage != null &&
                            state.sendToEReaderState ==
                                SendToEReaderState.error)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              state.errorMessage!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 20),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Material(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.0),
                              onTap: () {
                                if (state.sendToEReaderState ==
                                        SendToEReaderState.loading ||
                                    state.sendToEReaderState ==
                                        SendToEReaderState.downloading ||
                                    state.sendToEReaderState ==
                                        SendToEReaderState.uploading) {
                                  context.read<BookDetailsBloc>().add(
                                    CancelSendToEReader(),
                                  );
                                }
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      state.sendToEReaderState ==
                                                  SendToEReaderState.success ||
                                              state.sendToEReaderState ==
                                                  SendToEReaderState.error
                                          ? Icons.close
                                          : Icons.cancel_rounded,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      state.sendToEReaderState ==
                                                  SendToEReaderState.success ||
                                              state.sendToEReaderState ==
                                                  SendToEReaderState.error
                                          ? localizations.close
                                          : localizations.cancel,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(SendToEReaderState state, BuildContext context) {
    switch (state) {
      case SendToEReaderState.initial:
      case SendToEReaderState.loading:
        return const CircularProgressIndicator();
      case SendToEReaderState.downloading:
        return const Icon(Icons.download_rounded, size: 48);
      case SendToEReaderState.uploading:
        return const Icon(Icons.upload_rounded, size: 48);
      case SendToEReaderState.success:
        return Icon(
          Icons.check_circle,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        );
      case SendToEReaderState.error:
        return Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        );
      case SendToEReaderState.cancelled:
        return Icon(
          Icons.cancel_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.secondary,
        );
    }
  }

  String _getStatusMessage(
    SendToEReaderState state,
    AppLocalizations localizations,
  ) {
    switch (state) {
      case SendToEReaderState.initial:
      case SendToEReaderState.loading:
        return localizations.preparingTransfer;
      case SendToEReaderState.downloading:
        return localizations.downloadingBook;
      case SendToEReaderState.uploading:
        return localizations.sendToEReader;
      case SendToEReaderState.success:
        return localizations.successfullySentToEReader;
      case SendToEReaderState.error:
        return localizations.transferFailed;
      case SendToEReaderState.cancelled:
        return localizations.transferCancelled;
    }
  }
}
