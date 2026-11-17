import 'package:calibre_web_companion/core/theme/app_theme.dart';
import 'package:calibre_web_companion/features/homepage/app_destination.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_bloc.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_event.dart';
import 'package:calibre_web_companion/features/homepage/presentation/pages/home_page.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _all = [
  AppDestination.library,
  AppDestination.discover,
  AppDestination.onDevice,
];

/// A scrollable stub page so tab state survival can be checked.
class _Stub extends StatelessWidget {
  const _Stub(this.d);
  final AppDestination d;

  @override
  Widget build(BuildContext context) => ListView.builder(
    key: PageStorageKey(d),
    itemCount: 200,
    itemBuilder: (_, i) => SizedBox(height: 50, child: Text('${d.name} $i')),
  );
}

Future<HomePageBloc> _pump(
  WidgetTester tester, {
  bool offline = false,
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bloc = HomePageBloc();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.circulation(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider.value(
        value: bloc,
        child: HomeShell(visible: _all, offline: offline, pageFor: _Stub.new),
      ),
    ),
  );
  return bloc;
}

void main() {
  testWidgets('phones get a bottom bar with Library, Discover, On device', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final label in ['Library', 'Discover', 'On device']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('navigation meets tap-target and label guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('900dp windows get a navigation rail instead', (tester) async {
    await _pump(tester, size: const Size(900, 700));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Back from Discover returns to Library and keeps the app open', (
    tester,
  ) async {
    final bloc = await _pump(tester);
    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(bloc.state.destination, AppDestination.discover);

    final popped = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(popped, isTrue, reason: 'the shell handled Back');
    expect(bloc.state.destination, AppDestination.library);
    expect(find.text('library 0'), findsOneWidget);
  });

  testWidgets('offline shows the banner and moves to On device', (
    tester,
  ) async {
    await _pump(tester, offline: true);
    expect(find.textContaining("Can't reach your server"), findsOneWidget);
    expect(find.text('onDevice 0'), findsOneWidget);
  });

  testWidgets('Library keeps its scroll position across going offline', (
    tester,
  ) async {
    final bloc = HomePageBloc();
    Widget app(bool offline) => MaterialApp(
      theme: AppTheme.circulation(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider.value(
        value: bloc,
        child: HomeShell(visible: _all, offline: offline, pageFor: _Stub.new),
      ),
    );
    await tester.pumpWidget(app(false));
    await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('library 0'), findsNothing);

    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(false));
    await tester.pumpAndSettle();

    expect(bloc.state.destination, AppDestination.library);
    expect(find.text('library 0'), findsNothing, reason: 'still scrolled');
  });

  testWidgets('selecting a hidden destination falls back to Library', (
    tester,
  ) async {
    final bloc = await _pump(tester);
    bloc.add(const SelectDestination(AppDestination.requests));
    await tester.pumpAndSettle();
    expect(find.text('library 0'), findsOneWidget);
  });

  // Keep SystemNavigator.pop from failing when Back reaches the app root.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
}
