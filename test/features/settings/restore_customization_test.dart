import 'package:calibre_web_companion/core/services/widget_service.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_event.dart';
import 'package:calibre_web_companion/features/settings/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what gets persisted; every other call is unused here.
class _Repo implements SettingsRepository {
  final saved = <String, List<String>>{};

  @override
  Future<void> setBookActionsOrder(List<String> order) async =>
      saved['order'] = order;

  @override
  Future<void> setEnabledBookActions(List<String> enabled) async =>
      saved['enabled'] = enabled;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Widgets implements WidgetService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Undo after a reset restores and saves the previous order', () async {
    final repo = _Repo();
    final bloc = SettingsBloc(repository: repo, widgetService: _Widgets());

    bloc.add(
      const RestoreCustomization(
        bookActionsOrder: ['deleteBook', 'downloadToDevice'],
        enabledBookActions: ['downloadToDevice'],
      ),
    );
    final state = await bloc.stream.first;
    await pumpEventQueue();

    expect(state.bookActionsOrder, ['deleteBook', 'downloadToDevice']);
    expect(state.enabledBookActions, ['downloadToDevice']);
    expect(repo.saved['order'], ['deleteBook', 'downloadToDevice']);
    expect(repo.saved['enabled'], ['downloadToDevice']);
    await bloc.close();
  });
}
