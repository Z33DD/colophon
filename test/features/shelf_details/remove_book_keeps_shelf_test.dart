import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_bloc.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_event.dart';
import 'package:calibre_web_companion/features/shelf_details/bloc/shelf_details_state.dart';
import 'package:calibre_web_companion/features/shelf_details/data/repositories/shelf_details_repository.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_bloc.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/bloc/shelf_view_event.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/data/repositories/shelf_view_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _DetailsRepo implements ShelfDetailsRepository {
  @override
  Future<bool> removeFromShelf(String shelfId, String bookId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ShelfRepo implements ShelfViewRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records events instead of handling them.
class _RecordingShelfViewBloc extends ShelfViewBloc {
  _RecordingShelfViewBloc() : super(repository: _ShelfRepo());
  final events = <ShelfViewEvent>[];

  @override
  void add(ShelfViewEvent event) => events.add(event);
}

void main() {
  test(
    'removing a book from a shelf keeps the shelf in the shelf list',
    () async {
      // Regression: a successful removal also dispatched
      // RemoveShelfFromState(shelfId), so the whole shelf vanished from the
      // shelves list until it was reloaded.
      final shelves = _RecordingShelfViewBloc();
      final bloc = ShelfDetailsBloc(
        repository: _DetailsRepo(),
        shelfViewBloc: shelves,
      );

      bloc.add(const RemoveFromShelf('7', '42'));
      await bloc.stream.firstWhere((s) => s.action == ShelfAction.bookRemoved);

      expect(shelves.events.whereType<RemoveShelfFromState>(), isEmpty);
      await bloc.close();
      await shelves.close();
    },
  );
}
