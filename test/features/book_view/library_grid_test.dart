import 'package:calibre_web_companion/core/theme/app_theme.dart';
import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/library_grid.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _books = [
  for (var i = 0; i < 30; i++)
    BookViewModel(
      id: 0,
      uuid: 'u$i',
      title: 'A rather long book title number $i',
      authors: 'Author $i',
      readStatus: i.isEven,
    ),
];

Future<void> _pump(
  WidgetTester tester,
  double width, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.circulation(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
      home: Scaffold(
        body: LibraryGrid(
          books: _books,
          columnSetting: 3,
          onOpen: (_) {},
          onDevice: (b) => b.uuid == 'u1',
        ),
      ),
    ),
  );
}

int _columns(WidgetTester tester) {
  final tops =
      tester
          .widgetList<LibraryTile>(find.byType(LibraryTile))
          .map((t) => tester.getTopLeft(find.byWidget(t)).dy)
          .toList();
  return tops.where((y) => y == tops.first).length;
}

void main() {
  testWidgets('three covers across a 360dp phone', (tester) async {
    await _pump(tester, 360);
    expect(_columns(tester), 3);
  });

  testWidgets('landscape and tablets fit more covers at the same size', (
    tester,
  ) async {
    await _pump(tester, 800);
    expect(_columns(tester), greaterThanOrEqualTo(6));
  });

  testWidgets('labels do not overflow at 200% text', (tester) async {
    await _pump(tester, 360, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read and on-device books carry their stamps', (tester) async {
    await _pump(tester, 360);
    // Book 0 is read; book 1 is unread but on device.
    expect(find.text('READ'), findsWidgets);
    expect(find.text('ON DEVICE'), findsOneWidget);
  });

  test('cover size setting maps to a max cover width', () {
    expect(coverExtentFor(3), 140);
    expect(coverExtentFor(1), 420);
    expect(coverExtentFor(99), 70, reason: 'clamped to 6');
  });
}
