import 'dart:async';

import 'package:calibre_web_companion/core/services/library_events.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_state.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/library_filter.dart';
import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

class BookViewBloc extends Bloc<BookViewEvent, BookViewState> {
  final BookViewRepository repository;
  final Logger logger;

  static const int _seriesFolderLimit = 1000;

  BookViewBloc({required this.repository, required this.logger})
    : super(const BookViewState()) {
    on<LoadViewSettings>(_onLoadSettings);
    on<LoadBooks>(_onLoadBooks);
    on<LoadMoreBooks>(_onLoadMoreBooks);
    on<RefreshBooks>(_onRefreshBooks);
    on<ChangeSort>(_onChangeSort);
    on<EnterSeriesFolderMode>(_onEnterSeriesFolderMode);
    on<SearchBooks>(_onSearchBooks);
    on<UploadBook>(_onUploadBook);
    on<ChangeColumnCount>(_onChangeColumnCount);
    on<SetViewMode>(_onSetViewMode);
    on<UploadCancel>(_onUploadCancel);
    on<ResetUploadStatus>(_onResetUploadStatus);
    on<ChangeLibrary>(_onChangeLibrary);
    on<SetLibraryFilter>(_onSetLibraryFilter);
    on<ApplyBookChange>(_onApplyBookChange);
    if (GetIt.instance.isRegistered<LibraryEvents>()) {
      _changes = GetIt.instance<LibraryEvents>().stream.listen(
        (event) => add(ApplyBookChange(event)),
      );
    }
  }

  Future<void> _onLoadSettings(
    LoadViewSettings event,
    Emitter<BookViewState> emit,
  ) async {
    try {
      final columnCount = await repository.getColumnCount();
      final isListView = await repository.getIsListView();
      final caps = repository.getCapabilities();
      final libraries = repository.getLibraries();
      emit(
        state.copyWith(
          columnCount: columnCount,
          isListView: isListView,
          canAddBooks: caps.addBooks,
          canLookupMetadata: caps.metadataLookup,
          canBrowseSeriesFolders: caps.discover,
          // Filters use the OPDS lists that come with discover support.
          canFilter: caps.discover,
          multiLibrary: caps.multiLibrary && libraries.length > 1,
          libraries: libraries,
          currentLibraryId: repository.getCurrentLibraryId(),
        ),
      );
    } catch (e) {
      logger.e('Error loading settings: $e');
    }
  }

  Future<void> _onLoadBooks(
    LoadBooks event,
    Emitter<BookViewState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, hasError: false));
    if (!state.filter.isAll) return _loadFiltered(emit, reset: true);
    try {
      final isOpds = repository.getIsOpds();
      final caps = repository.getCapabilities();
      final limit = state.seriesFolderMode ? _seriesFolderLimit : state.limit;

      final books = await repository.fetchBooks(
        offset: 0,
        limit: limit,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
      );

      emit(
        state.copyWith(
          isLoading: false,
          books: _scoped(books),
          offset: limit,
          hasMoreBooks:
              state.seriesFolderMode
                  ? false
                  : (caps.pagination ? books.isNotEmpty : false),
          isOpds: isOpds,
        ),
      );
    } catch (e) {
      logger.e('Error loading books: $e');
      emit(
        state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreBooks(
    LoadMoreBooks event,
    Emitter<BookViewState> emit,
  ) async {
    if (state.isLoading || !state.hasMoreBooks) return;

    emit(state.copyWith(isLoading: true));
    if (!state.filter.isAll) return _loadFiltered(emit, reset: false);

    try {
      final moreBooks = await repository.fetchBooks(
        offset: state.offset,
        limit: state.limit,
        searchQuery: state.searchQuery,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
      );

      final allBooks = [...state.books, ..._scoped(moreBooks)];

      emit(
        state.copyWith(
          books: allBooks,
          isLoading: false,
          hasMoreBooks: moreBooks.isNotEmpty,
          offset: state.offset + state.limit,
        ),
      );
    } catch (e) {
      logger.e('Error loading more books: $e');
      emit(
        state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshBooks(
    RefreshBooks event,
    Emitter<BookViewState> emit,
  ) async {
    emit(
      state.copyWith(
        offset: 0,
        books: [],
        hasMoreBooks: true,
        isLoading: false,
        hasError: false,
        errorMessage: '',
      ),
    );

    add(const LoadBooks());
  }

  Future<void> _onChangeSort(
    ChangeSort event,
    Emitter<BookViewState> emit,
  ) async {
    logger.i('Sorting by ${event.sortBy} ${event.sortOrder}');

    emit(
      state.copyWith(
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        seriesFolderMode: false,
        offset: 0,
        books: [],
        hasMoreBooks: true,
      ),
    );

    add(const LoadBooks());
  }

  Future<void> _onEnterSeriesFolderMode(
    EnterSeriesFolderMode event,
    Emitter<BookViewState> emit,
  ) async {
    emit(
      state.copyWith(
        sortBy: 'series',
        sortOrder: 'asc',
        seriesFolderMode: true,
        isLoading: true,
        offset: 0,
        books: [],
        hasMoreBooks: true,
      ),
    );

    add(const LoadBooks());
  }

  Future<void> _onSearchBooks(
    SearchBooks event,
    Emitter<BookViewState> emit,
  ) async {
    emit(
      state.copyWith(
        searchQuery: event.query,
        searchScope: event.scope,
        // Filtered OPDS lists can't be searched: searching shows All.
        filter: LibraryFilter.all,
        filterNextUrl: () => null,
        seriesFolderMode: false,
        offset: 0,
        books: [],
        hasMoreBooks: true,
      ),
    );

    add(const LoadBooks());
  }

  StreamSubscription<BookChanged>? _changes;

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }

  /// Keeps the list current after a change elsewhere, in place where
  /// possible so the scroll position survives.
  void _onApplyBookChange(ApplyBookChange event, Emitter<BookViewState> emit) {
    final change = event.change;
    final books = state.books;
    switch (change.change) {
      case BookChange.readStatus:
        final read = change.read;
        if (read == null) break;
        final implied = state.filter.impliedReadStatus;
        emit(
          state.copyWith(
            books: [
              for (final b in books)
                if (b.id != change.bookId)
                  b
                // Drop it from a Read/Unread list it no longer belongs to.
                else if (implied == null || implied == read)
                  b.copyWith(readStatus: read),
            ],
          ),
        );
      case BookChange.deleted || BookChange.archived:
        emit(
          state.copyWith(
            books: [
              for (final b in books)
                if (b.id != change.bookId) b,
            ],
          ),
        );
      case BookChange.download || BookChange.progress:
        // Same books, new On device or progress stamp.
        emit(state.copyWith(localRevision: state.localRevision + 1));
      case BookChange.metadata || BookChange.shelves:
        add(const RefreshBooks());
    }
  }

  Future<void> _onSetLibraryFilter(
    SetLibraryFilter event,
    Emitter<BookViewState> emit,
  ) async {
    emit(
      state.copyWith(
        filter: event.filter,
        filterNextUrl: () => null,
        searchQuery: '',
        searchScope: SearchScope.any,
        seriesFolderMode: false,
        offset: 0,
        books: [],
        hasMoreBooks: true,
        hasError: false,
      ),
    );
    add(const LoadBooks());
  }

  /// Loads the first ([reset]) or next page of the active filter.
  Future<void> _loadFiltered(
    Emitter<BookViewState> emit, {
    required bool reset,
  }) async {
    try {
      final page = await repository.fetchFilteredPage(
        state.filter,
        nextUrl: reset ? null : state.filterNextUrl,
      );
      emit(
        state.copyWith(
          isLoading: false,
          books: reset ? page.books : [...state.books, ...page.books],
          filterNextUrl: () => page.next,
          hasMoreBooks: page.next != null,
          isOpds: repository.getIsOpds(),
        ),
      );
    } catch (e) {
      logger.e('Error loading filtered books: $e');
      emit(
        state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Applies a typed suggestion's scope to a page from the server's
  /// free-text search.
  List<BookViewModel> _scoped(List<BookViewModel> books) {
    final term = state.searchQuery ?? '';
    if (state.searchScope == SearchScope.any || term.isEmpty) return books;
    return books
        .where((b) => matchesScope(b, state.searchScope, term))
        .toList();
  }

  Future<void> _onUploadBook(
    UploadBook event,
    Emitter<BookViewState> emit,
  ) async {
    emit(
      state.copyWith(
        uploadStatus: UploadStatus.loading,
        hasError: false,
        errorMessage: '',
      ),
    );

    try {
      emit(state.copyWith(uploadStatus: UploadStatus.uploading));

      final result = await repository.uploadEbook(
        event.book,
        fileName: event.fileName,
      );

      emit(
        state.copyWith(
          uploadStatus: result ? UploadStatus.success : UploadStatus.failed,
        ),
      );

      if (result) {
        add(const RefreshBooks());
      }
    } catch (e) {
      logger.e('Error uploading book: $e');
      emit(
        state.copyWith(
          uploadStatus: UploadStatus.failed,
          hasError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onChangeColumnCount(
    ChangeColumnCount event,
    Emitter<BookViewState> emit,
  ) async {
    try {
      await repository.setColumnCount(event.count);
      await repository.setIsListView(false);
      emit(state.copyWith(columnCount: event.count, isListView: false));
    } catch (e) {
      logger.e('Error changing column count: $e');
    }
  }

  Future<void> _onSetViewMode(
    SetViewMode event,
    Emitter<BookViewState> emit,
  ) async {
    try {
      await repository.setIsListView(event.isListView);
      emit(state.copyWith(isListView: event.isListView));
    } catch (e) {
      logger.e('Error changing view mode: $e');
    }
  }

  Future<void> _onChangeLibrary(
    ChangeLibrary event,
    Emitter<BookViewState> emit,
  ) async {
    if (event.libraryId == state.currentLibraryId) return;

    await repository.setCurrentLibraryId(event.libraryId);
    emit(
      state.copyWith(
        currentLibraryId: event.libraryId,
        books: [],
        offset: 0,
        hasMoreBooks: true,
        searchQuery: '',
      ),
    );
    add(const LoadBooks());
  }

  void _onUploadCancel(UploadCancel event, Emitter<BookViewState> emit) {
    emit(state.copyWith(uploadStatus: UploadStatus.initial));
  }

  void _onResetUploadStatus(
    ResetUploadStatus event,
    Emitter<BookViewState> emit,
  ) {
    emit(state.copyWith(uploadStatus: UploadStatus.initial));
  }
}
