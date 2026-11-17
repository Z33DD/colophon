import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/core/theme/app_theme.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/ui/action_bar.dart';
import 'package:calibre_web_companion/shared/ui/book_cover.dart';
import 'package:calibre_web_companion/shared/ui/book_stamp.dart';
import 'package:calibre_web_companion/shared/ui/settings_tiles.dart';
import 'package:calibre_web_companion/shared/ui/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double width = 360}) => MaterialApp(
  theme: AppTheme.circulation(Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
);

Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  group('BookCover', () {
    testWidgets('announces title, author and every stamp', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 120,
            child: BookCover(
              title: 'Dune',
              author: 'Frank Herbert',
              stamps: [ReadStamp(DateTime(2026, 11, 3)), const OnDeviceStamp()],
              onTap: () {},
            ),
          ),
        ),
      );

      // One focus stop per book: the stamps merge into the cover's label.
      expect(
        find.bySemanticsLabel(
          RegExp(r'Dune by Frank Herbert[\s\S]*Read 03 Nov[\s\S]*On device'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a book without a cover shows its title, not a broken image', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 120,
            child: BookCover(title: 'Piranesi', author: 'Susanna Clarke'),
          ),
        ),
      );
      expect(find.text('Piranesi'), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    });
  });

  group('ActionBar', () {
    testWidgets('all actions fit at 360dp with long German labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          Padding(
            padding: const EdgeInsets.all(16),
            child: ActionBar(
              primary: BarAction(
                icon: Icons.menu_book,
                label: 'Lesen',
                onPressed: () {},
              ),
              secondary: [
                BarAction(
                  icon: Icons.download,
                  label: 'Herunterladen',
                  onPressed: () {},
                ),
                BarAction(
                  icon: Icons.send,
                  label: 'An E-Reader senden',
                  onPressed: () {},
                ),
                BarAction(
                  icon: Icons.bookmark_add,
                  label: 'Zum Regal hinzufügen',
                  onPressed: () {},
                ),
              ],
              overflow: [
                BarAction(
                  icon: Icons.delete,
                  label: 'Löschen',
                  onPressed: () {},
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull, reason: 'no overflow errors');
      for (final label in [
        'Lesen',
        'Herunterladen',
        'An E-Reader senden',
        'Zum Regal hinzufügen',
      ]) {
        final rect = tester.getRect(find.text(label));
        expect(rect.right, lessThanOrEqualTo(360));
      }
      expect(
        find.text('Löschen'),
        findsNothing,
        reason: 'delete lives in overflow',
      );
      await _expectAccessible(tester);
      handle.dispose();
    });

    testWidgets('overflow menu opens and runs its action', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        _host(
          ActionBar(
            primary: BarAction(
              icon: Icons.menu_book,
              label: 'Read',
              onPressed: () {},
            ),
            overflow: [
              BarAction(
                icon: Icons.delete,
                label: 'Delete',
                onPressed: () => deleted = true,
                isDestructive: true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('a running primary action shows progress and is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ActionBar(
            primary: BarAction(
              icon: Icons.download,
              label: 'Download',
              onPressed: () {},
              progress: 0.4,
            ),
          ),
        ),
      );
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.4);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });
  });

  group('Settings tiles', () {
    testWidgets('group rows are labelled 48dp targets', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SettingsGroup(
            title: 'Appearance',
            children: [
              SettingsTile(
                icon: Icons.palette,
                title: 'Theme',
                subtitle: 'Companion',
                onTap: () {},
              ),
              SettingsSwitch(
                icon: Icons.contrast,
                title: 'E-ink mode',
                value: false,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('APPEARANCE'), findsOneWidget);
      await _expectAccessible(tester);
      handle.dispose();
    });
  });

  group('StatusView', () {
    testWidgets('error shows its retry action once', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        _host(
          StatusView.error(
            title: 'Could not load the library',
            actionLabel: 'Retry',
            onAction: () => retried++,
          ),
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });

  group('showSnackBar', () {
    testWidgets('offers an action when given one', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        _host(
          Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => context.showSnackBar(
                        'Downloaded Dune',
                        actionLabel: 'Open',
                        onAction: () => opened = true,
                      ),
                  child: const Text('go'),
                ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      expect(opened, isTrue);
    });
  });
}
