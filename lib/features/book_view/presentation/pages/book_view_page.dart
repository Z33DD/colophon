import 'dart:io';

import 'package:calibre_web_companion/core/navigation/app_route.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/features/book_details/presentation/pages/book_details_page.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_state.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/book_view/presentation/pages/series_detail_page.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/library_grid.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/library_header.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/series_folder_card.dart';
import 'package:calibre_web_companion/features/me/presentation/widgets/account_button.dart';
import 'package:calibre_web_companion/features/offline/cubit/connectivity_cubit.dart';
import 'package:calibre_web_companion/features/offline/data/services/offline_backfill_service.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/pages/scan_book_page.dart';
import 'package:calibre_web_companion/features/scan_book/presentation/scan_flow.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/ui/status_view.dart';
import 'package:calibre_web_companion/shared/widgets/app_options_sheet.dart';
import 'package:calibre_web_companion/shared/widgets/book_card_skeleton_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_list_tile_skeleton_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_list_tile_widget.dart';
import 'package:calibre_web_companion/shared/widgets/book_view_mode_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class BookViewPage extends StatefulWidget {
  const BookViewPage({super.key});

  @override
  State<BookViewPage> createState() => _BookViewPageState();
}

class _BookViewPageState extends State<BookViewPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isUploadSheetShown = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final bloc = context.read<BookViewBloc>();
    final state = bloc.state;

    if (!state.isLoading &&
        state.hasMoreBooks &&
        _scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 500) {
      bloc.add(const LoadMoreBooks());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocConsumer<BookViewBloc, BookViewState>(
      listenWhen:
          (previous, current) =>
              previous.uploadStatus != current.uploadStatus ||
              (current.hasError && !previous.hasError) ||
              (previous.isLoading && !current.isLoading),
      listener: (context, state) {
        if (state.uploadStatus == UploadStatus.loading ||
            state.uploadStatus == UploadStatus.uploading) {
          _showUploadStatusSheet(context, localizations);
        }

        if (state.hasError) {
          // The error is shown inline by the body; no snackbar on top.
          context.read<ConnectivityCubit>().reportFailure();
        }

        if (!state.isLoading && !state.hasError && state.books.isNotEmpty) {
          context.read<ConnectivityCubit>().reportSuccess();
          GetIt.instance<OfflineBackfillService>().run();
        }
      },
      builder: (context, state) {
        // Compact header: the search pill is the title; filters and sort
        // share one row below it.
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: 12,
            title:
                state.isOpds
                    ? Text(localizations.navLibrary)
                    : LibrarySearchField(state: state),
            actions: [
              if (state.multiLibrary) _buildLibrarySelector(context, state),
              const BookViewModeSelector(),
              const AccountButton(),
            ],
          ),
          body: Column(
            children: [
              if (!state.isOpds) LibraryFilterBar(state: state),
              Expanded(child: _buildBody(context, state, localizations)),
            ],
          ),
          floatingActionButton:
              state.canAddBooks
                  ? FloatingActionButton(
                    onPressed:
                        () => _showAddBookOptions(context, localizations),
                    tooltip: localizations.addBook,
                    child: const Icon(Icons.add_rounded),
                  )
                  : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    BookViewState state,
    AppLocalizations localizations,
  ) {
    if (state.books.isEmpty && state.isLoading) {
      if (state.isListView) {
        return _buildBookListSkeletons(context);
      } else {
        return _buildBookGridSkeletons(state);
      }
    }

    if (state.books.isEmpty) {
      final bloc = context.read<BookViewBloc>();
      final narrowed = (state.searchQuery ?? '').isNotEmpty;
      final Widget status;
      if (state.hasError) {
        status = StatusView.error(
          title: localizations.libraryLoadErrorTitle,
          message: localizations.libraryLoadErrorMessage,
          actionLabel: localizations.retry,
          onAction: () => bloc.add(const RefreshBooks()),
        );
      } else if (narrowed) {
        status = StatusView.empty(
          icon: Icons.search_off_rounded,
          title: localizations.libraryNoResultsTitle,
          message: localizations.libraryNoResultsMessage,
          actionLabel: localizations.clearSearch,
          onAction: () => bloc.add(const SearchBooks('')),
        );
      } else {
        status = StatusView.empty(
          icon: Icons.auto_stories_outlined,
          title: localizations.libraryEmptyTitle,
          message: localizations.libraryEmptyMessage,
        );
      }
      // Scrollable so pull-to-refresh still works on an empty library.
      return RefreshIndicator(
        onRefresh: () async => bloc.add(const RefreshBooks()),
        child: LayoutBuilder(
          builder:
              (context, box) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: box.maxHeight, child: status),
              ),
        ),
      );
    }

    if (state.seriesFolderMode) {
      return _buildSeriesFolderGrid(context, state);
    }

    return RefreshIndicator(
      onRefresh: () {
        context.read<BookViewBloc>().add(const RefreshBooks());
        return Future.value();
      },
      child:
          state.isListView
              ? ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount:
                    state.hasMoreBooks
                        ? state.books.length + 1
                        : state.books.length,
                itemBuilder: (context, index) {
                  if (index == state.books.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final book = state.books[index];
                  return BookListTile(
                    book: book,
                    onTap: () => _openBook(context, book),
                  );
                },
              )
              : LibraryGrid(
                controller: _scrollController,
                books: state.books,
                columnSetting: state.columnCount,
                showLoadingTail: state.hasMoreBooks,
                onOpen: (book) => _openBook(context, book),
              ),
    );
  }

  Future<void> _openBook(BuildContext context, BookViewModel book) async {
    final changed = await Navigator.of(context).push<bool>(
      AppRoute.page(BookDetailsPage(bookViewModel: book, bookUuid: book.uuid)),
    );
    if (changed == true && context.mounted) {
      context.read<BookViewBloc>().add(const RefreshBooks());
    }
  }

  Widget _buildBookListSkeletons(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 10,
      itemBuilder: (context, index) {
        return const BookListTileSkeleton();
      },
    );
  }

  Widget _buildBookGridSkeletons(BookViewState state) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: coverExtentFor(state.columnCount),
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
        childAspectRatio: 0.55,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => const BookCardSkeleton(),
    );
  }

  Widget _buildSeriesFolderGrid(BuildContext context, BookViewState state) {
    final groups = <String, List<BookViewModel>>{};
    for (final book in state.books) {
      final series = book.series.trim();
      if (series.isEmpty) continue;
      groups.putIfAbsent(series, () => <BookViewModel>[]).add(book);
    }
    for (final books in groups.values) {
      books.sort((a, b) {
        final byIndex = a.seriesIndex.compareTo(b.seriesIndex);
        if (byIndex != 0) return byIndex;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    }
    final folders = groups.entries.toList();

    return RefreshIndicator(
      onRefresh: () {
        context.read<BookViewBloc>().add(const RefreshBooks());
        return Future.value();
      },
      child:
          folders.isEmpty
              ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.folder_off_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      AppLocalizations.of(context)!.noBooksFound,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              )
              : state.isListView
              ? ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final entry = folders[index];
                  return SeriesFolderListTile(
                    seriesName: entry.key,
                    books: entry.value,
                    onTap: () => _openSeriesDetail(context, entry),
                  );
                },
              )
              : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: state.columnCount,
                  childAspectRatio: state.columnCount <= 2 ? 0.7 : 0.9,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final entry = folders[index];
                  return SeriesFolderCard(
                    seriesName: entry.key,
                    books: entry.value,
                    onTap: () => _openSeriesDetail(context, entry),
                  );
                },
              ),
    );
  }

  void _openSeriesDetail(
    BuildContext context,
    MapEntry<String, List<BookViewModel>> entry,
  ) {
    Navigator.of(context).push(
      AppRoute.page(
        SeriesDetailPage(seriesName: entry.key, books: entry.value),
      ),
    );
  }

  Widget _buildLibrarySelector(BuildContext context, BookViewState state) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.library_books_rounded),
      tooltip: state.libraries[state.currentLibraryId] ?? 'Library',
      onSelected: (String libraryId) {
        context.read<BookViewBloc>().add(ChangeLibrary(libraryId));
      },
      itemBuilder:
          (BuildContext context) =>
              state.libraries.entries
                  .map(
                    (entry) => CheckedPopupMenuItem<String>(
                      value: entry.key,
                      checked: entry.key == state.currentLibraryId,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
    );
  }

  void _showAddBookOptions(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final canLookupMetadata =
        context.read<BookViewBloc>().state.canLookupMetadata;

    showAppOptionsSheet(
      context,
      title: localizations.addBook,
      options: [
        if (canLookupMetadata)
          AppSheetOption(
            icon: Icons.qr_code_scanner_rounded,
            title: localizations.scan,
            subtitle: localizations.scanBarcodeDescription,
            onTap: () => _openScanner(context),
          ),
        if (canLookupMetadata)
          AppSheetOption(
            icon: Icons.keyboard_rounded,
            title: localizations.enterIsbn,
            subtitle: localizations.enterIsbnDescription,
            onTap: () => _startIsbnEntry(context),
          ),
        AppSheetOption(
          icon: Icons.upload_file_rounded,
          title: localizations.uploadFromDevice,
          subtitle: localizations.uploadFromDeviceDescription,
          onTap: () => _pickAndUploadBook(context, localizations),
        ),
      ],
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final added = await Navigator.of(
      context,
    ).push<bool>(AppRoute.page(const ScanBookPage()));
    if (added == true && context.mounted) {
      context.read<BookViewBloc>().add(const RefreshBooks());
    }
  }

  Future<void> _startIsbnEntry(BuildContext context) async {
    final isbn = await promptForIsbn(context);
    if (isbn == null || isbn.isEmpty || !context.mounted) return;
    final added = await runIsbnLookupFlow(context, isbn);
    if (added && context.mounted) {
      context.read<BookViewBloc>().add(const RefreshBooks());
    }
  }

  Future<void> _pickAndUploadBook(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'mobi', 'fb2', 'cbr', 'djvu', 'cbz'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      if (!context.mounted) return;
      context.showSnackBar(localizations.noFilesSelected, isError: true);
      return;
    }

    final picked = result.files.single;
    final file = File(picked.path!);
    if (!context.mounted) return;
    context.read<BookViewBloc>().add(UploadBook(file, fileName: picked.name));
  }

  void _showUploadStatusSheet(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    if (_isUploadSheetShown) return;
    _isUploadSheetShown = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .54),
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: BlocBuilder<BookViewBloc, BookViewState>(
            buildWhen:
                (previous, current) =>
                    previous.uploadStatus != current.uploadStatus ||
                    previous.errorMessage != current.errorMessage,
            builder: (context, state) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusIcon(state.uploadStatus),
                      const SizedBox(height: 20),

                      Text(
                        _getStatusMessage(state.uploadStatus, localizations),
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (state.hasError &&
                          state.uploadStatus == UploadStatus.failed)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorMessage,
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

                      if (state.uploadStatus == UploadStatus.loading ||
                          state.uploadStatus == UploadStatus.uploading)
                        LinearProgressIndicator(
                          backgroundColor:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
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
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: () {
                              if (state.uploadStatus == UploadStatus.loading ||
                                  state.uploadStatus ==
                                      UploadStatus.uploading) {
                                context.read<BookViewBloc>().add(
                                  const UploadCancel(),
                                );
                              } else if (state.uploadStatus ==
                                      UploadStatus.success ||
                                  state.uploadStatus == UploadStatus.failed) {
                                context.read<BookViewBloc>().add(
                                  const ResetUploadStatus(),
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
                                    state.uploadStatus ==
                                                UploadStatus.success ||
                                            state.uploadStatus ==
                                                UploadStatus.failed
                                        ? Icons.close
                                        : Icons.cancel_rounded,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    state.uploadStatus ==
                                                UploadStatus.success ||
                                            state.uploadStatus ==
                                                UploadStatus.failed
                                        ? localizations.close
                                        : localizations.cancel,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
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
        );
      },
    ).then((_) {
      _isUploadSheetShown = false;
    });
  }

  Widget _buildStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.loading:
        return const CircularProgressIndicator();
      case UploadStatus.uploading:
        return const Icon(Icons.upload_rounded, size: 48);
      case UploadStatus.success:
        return Icon(
          Icons.check_circle,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        );
      case UploadStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        );
      default:
        return const SizedBox();
    }
  }

  String _getStatusMessage(
    UploadStatus status,
    AppLocalizations localizations,
  ) {
    switch (status) {
      case UploadStatus.loading:
        return localizations.preparingUpload;
      case UploadStatus.uploading:
        return localizations.uploadingBook;
      case UploadStatus.success:
        return localizations.sucessfullyUploadedBook;
      case UploadStatus.failed:
        return localizations.uploadFailed;
      default:
        return '';
    }
  }
}
