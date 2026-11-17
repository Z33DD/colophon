import 'package:calibre_web_companion/core/theme/app_theme.dart';
import 'package:calibre_web_companion/features/book_details/data/models/book_details_model.dart';
import 'package:calibre_web_companion/features/book_details/presentation/widgets/book_header.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _book = BookDetailsModel(
  id: 0, // no network cover in tests
  uuid: 'u',
  title: 'Die unendliche Geschichte: Von A bis Z',
  authors: 'Michael Ende',
  series: 'Phantásien',
  seriesIndex: 1,
);

Future<void> _pump(
  WidgetTester tester, {
  required bool isRead,
  VoidCallback? onToggleRead,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.circulation(Brightness.light),
      locale: const Locale('de'),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: BookHeader(
            book: _book,
            isRead: isRead,
            isArchived: false,
            onDevice: false,
            onToggleRead: onToggleRead ?? () {},
            onToggleArchived: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('the read toggle states the current state', (tester) async {
    // Regression: read status used an eye icon showing the opposite action,
    // so the current state could not be told from the button.
    await _pump(tester, isRead: false);
    final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
    expect(chips.first.selected, isFalse);

    await _pump(tester, isRead: true);
    expect(
      tester.widgetList<FilterChip>(find.byType(FilterChip)).first.selected,
      isTrue,
    );
  });

  testWidgets('tapping the read toggle runs the action', (tester) async {
    var toggled = false;
    await _pump(tester, isRead: false, onToggleRead: () => toggled = true);
    await tester.tap(find.byType(FilterChip).first);
    expect(toggled, isTrue);
  });

  testWidgets('German at 200% text lays out without overflow', (tester) async {
    await _pump(tester, isRead: true, textScale: 2);
    expect(tester.takeException(), isNull);
  });

  test('descriptions keep their paragraphs', () {
    // Regression: tags were stripped by regex and paragraphs ran together.
    expect(
      BookDetailsModel.removeHtmlTags(
        '<p>First &amp; best.</p><p>Second<br>line</p>',
      ),
      'First & best.\n\nSecond\nline',
    );
  });
}
