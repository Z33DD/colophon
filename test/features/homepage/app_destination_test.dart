import 'package:calibre_web_companion/features/homepage/app_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visibleDestinations', () {
    test('Shelfmark off shows Library, Discover, On device', () {
      expect(
        visibleDestinations(serverType: 'calibreWeb', downloaderEnabled: false),
        [
          AppDestination.library,
          AppDestination.discover,
          AppDestination.onDevice,
        ],
      );
    });

    test('Shelfmark on adds Requests last', () {
      expect(
        visibleDestinations(
          serverType: 'calibreWeb',
          downloaderEnabled: true,
        ).last,
        AppDestination.requests,
      );
    });

    test('a server without discover support has no Discover', () {
      expect(
        visibleDestinations(serverType: 'calibre', downloaderEnabled: false),
        isNot(contains(AppDestination.discover)),
      );
    });
  });

  group('resolveDestination', () {
    test('a link to a hidden destination falls back to Library', () {
      // Regression: the "downloads" widget action used a tab index, so with
      // Shelfmark off it pointed past the end and opened the wrong tab.
      final visible = visibleDestinations(
        serverType: 'calibreWeb',
        downloaderEnabled: false,
      );
      expect(
        resolveDestination(AppDestination.requests, visible),
        AppDestination.library,
      );
    });

    test('a visible destination is kept', () {
      final visible = visibleDestinations(
        serverType: 'calibreWeb',
        downloaderEnabled: true,
      );
      expect(
        resolveDestination(AppDestination.requests, visible),
        AppDestination.requests,
      );
    });
  });

  test('only On device works without the server', () {
    expect(AppDestination.values.where((d) => !d.needsServer), [
      AppDestination.onDevice,
    ]);
  });
}
