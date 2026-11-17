import 'package:calibre_web_companion/core/services/widget_service.dart';
import 'package:calibre_web_companion/core/theme/app_theme.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';
import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/data/repositories/login_repository.dart';
import 'package:calibre_web_companion/features/me/bloc/me_bloc.dart';
import 'package:calibre_web_companion/features/me/data/models/stats_model.dart';
import 'package:calibre_web_companion/features/me/data/repositories/me_repository.dart';
import 'package:calibre_web_companion/features/me/presentation/pages/me_page.dart';
import 'package:calibre_web_companion/features/me/presentation/widgets/account_button.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/data/repositories/settings_repository.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MeRepo implements MeRepository {
  @override
  Future<StatsModel> getStats() => Future.error(Exception('offline'));
  @override
  bool getIsOpds() => false;
  @override
  bool getShowStats() => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LoginRepo implements LoginRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BookRepo implements BookViewRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SettingsRepo implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Widgets implements WidgetService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'username': 'pedro'});
    final prefs = await SharedPreferences.getInstance();
    final getIt = GetIt.instance;
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerFactory<MeBloc>(
      () => MeBloc(repository: _MeRepo(), widgetService: _Widgets()),
    );
  });
  tearDown(() => GetIt.instance.reset());

  testWidgets('the avatar opens the account page', (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (_) => SettingsBloc(
                  repository: _SettingsRepo(),
                  widgetService: _Widgets(),
                ),
          ),
          BlocProvider(
            create:
                (_) => LoginBloc(
                  loginRepository: _LoginRepo(),
                  logger: Logger(level: Level.off),
                ),
          ),
          BlocProvider(
            create:
                (_) => BookViewBloc(
                  repository: _BookRepo(),
                  logger: Logger(level: Level.off),
                ),
          ),
          BlocProvider(
            create:
                (_) => MeBloc(repository: _MeRepo(), widgetService: _Widgets()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.circulation(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(appBar: AppBar(actions: const [AccountButton()])),
        ),
      ),
    );

    await tester.tap(find.byType(AccountButton));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(MePage), findsOneWidget);
  });
}
