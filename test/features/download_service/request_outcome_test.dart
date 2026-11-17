import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:calibre_web_companion/features/download_service/data/repositories/download_service_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

const _book = DownloadServiceBookModel(
  id: 'b1',
  title: 'Dune',
  author: 'Herbert',
  format: 'epub',
  size: '1 MB',
  preview: '',
  publisher: '',
  year: '1965',
  language: 'en',
);

class _Repo implements DownloadServiceRepository {
  _Repo(this.accept);
  final bool accept;

  @override
  Future<bool> downloadBook(DownloadServiceBookModel book) async => accept;

  @override
  Future<List<DownloadServiceBookModel>> getDownloadStatus() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'a rejected request stays on its card, not over the whole list',
    () async {
      // Regression: a failed request set the global errorMessage, which
      // replaced the Downloads tab with an error, after an optimistic
      // "added to queue" snackbar had already been shown.
      final bloc = DownloadServiceBloc(
        repository: _Repo(false),
        logger: Logger(level: Level.off),
      );
      bloc.add(const DownloadBook(_book));
      final state = await bloc.stream.firstWhere(
        (s) => s.failedRequests.isNotEmpty,
      );

      expect(state.failedRequests.keys, ['b1']);
      expect(state.queuedRequests, isEmpty);
      expect(state.errorMessage, isNull);
      await bloc.close();
    },
  );

  test('an accepted request is marked queued', () async {
    final bloc = DownloadServiceBloc(
      repository: _Repo(true),
      logger: Logger(level: Level.off),
    );
    bloc.add(const DownloadBook(_book));
    final state = await bloc.stream.firstWhere(
      (s) => s.queuedRequests.isNotEmpty,
    );

    expect(state.queuedRequests, {'b1'});
    expect(state.failedRequests, isEmpty);
    await bloc.close();
  });
}
