import 'package:calibre_web_companion/core/services/library_events.dart';
import 'package:calibre_web_companion/core/services/server_capabilities.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_state.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/book_view/data/models/library_filter.dart';
import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

const _books = [
  BookViewModel(id: 1, uuid: 'a', title: 'Dune', authors: 'Herbert'),
  BookViewModel(id: 2, uuid: 'b', title: 'Emma', authors: 'Austen'),
];

class _Repo implements BookViewRepository {
  @override
  Future<List<BookViewModel>> fetchBooks({
    required int offset,
    required int limit,
    String? searchQuery,
    String sortBy = '',
    String sortOrder = '',
  }) async => offset == 0 ? _books : const [];

  @override
  Future<({List<BookViewModel> books, String? next})> fetchFilteredPage(
    LibraryFilter filter, {
    String? nextUrl,
  }) async => (books: _books, next: null);

  @override
  bool getIsOpds() => false;

  @override
  ServerCapabilities getCapabilities() => ServerCapabilities.calibreWeb;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BookViewBloc> _loaded(LibraryFilter filter) async {
  final bloc = BookViewBloc(
    repository: _Repo(),
    logger: Logger(level: Level.off),
  );
  bloc.add(SetLibraryFilter(filter));
  await bloc.stream.firstWhere((s) => s.books.isNotEmpty && !s.isLoading);
  return bloc;
}

void main() {
  late LibraryEvents events;
  setUp(() {
    events = LibraryEvents();
    GetIt.instance.registerSingleton(events);
  });
  tearDown(() => GetIt.instance.reset());

  test(
    'marking a book read on its page updates it in the Library list',
    () async {
      // Regression: details only reported "changed" through Navigator.pop,
      // which forced PopScope(canPop: false) and broke predictive back.
      final bloc = await _loaded(LibraryFilter.all);
      events.publish(const BookChanged(1, BookChange.readStatus, read: true));
      final state = await bloc.stream.first;

      expect(state.books.firstWhere((b) => b.id == 1).readStatus, isTrue);
      expect(state.books, hasLength(2), reason: 'updated in place');
      await bloc.close();
    },
  );

  test('a book marked read leaves the Unread list', () async {
    final bloc = await _loaded(LibraryFilter.unread);
    events.publish(const BookChanged(1, BookChange.readStatus, read: true));
    final BookViewState state = await bloc.stream.first;

    expect(state.books.map((b) => b.id), [2]);
    await bloc.close();
  });

  test('a deleted book disappears', () async {
    final bloc = await _loaded(LibraryFilter.all);
    events.publish(const BookChanged(2, BookChange.deleted));
    final state = await bloc.stream.first;

    expect(state.books.map((b) => b.id), [1]);
    await bloc.close();
  });
}
