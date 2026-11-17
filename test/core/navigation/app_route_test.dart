import 'package:calibre_web_companion/core/navigation/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({required bool disableAnimations}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: MaterialApp(
    home: Builder(
      builder:
          (context) => TextButton(
            onPressed:
                () => Navigator.of(
                  context,
                ).push(AppRoute.page(const Text('details'))),
            child: const Text('open'),
          ),
    ),
  ),
);

void main() {
  testWidgets('with reduced motion the next page shows without a transition', (
    tester,
  ) async {
    await tester.pumpWidget(_app(disableAnimations: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    // Fully visible on the first frames: no slide or fade wrapper offset.
    expect(find.text('details'), findsOneWidget);
    final box = tester.getTopLeft(find.text('details'));
    expect(box.dx, lessThan(50));
    expect(
      find.ancestor(
        of: find.text('details'),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('with motion on, the platform page transition runs', (
    tester,
  ) async {
    await tester.pumpWidget(_app(disableAnimations: false));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
  });

  testWidgets('AppRoute is a MaterialPageRoute so predictive back applies', (
    tester,
  ) async {
    expect(AppRoute.page(const SizedBox()), isA<MaterialPageRoute<void>>());
  });
}
