/// Top-level areas of the app, addressed by identity rather than by tab
/// index, so hiding a tab never shifts where a link or widget lands.
enum AppDestination {
  library(needsServer: true),
  discover(needsServer: true),
  onDevice(needsServer: false),

  /// Shelfmark book requests; only when the downloader is configured.
  requests(needsServer: true);

  const AppDestination({required this.needsServer});

  /// Disabled while the server is unreachable.
  final bool needsServer;
}

/// Destinations shown for this server, in navigation order.
///
/// The Calibre content server (`server_type == 'calibre'`) has no discover
/// endpoints, so Discover is omitted rather than shown as a placeholder.
List<AppDestination> visibleDestinations({
  required String? serverType,
  required bool downloaderEnabled,
}) => [
  AppDestination.library,
  if (serverType != 'calibre') AppDestination.discover,
  AppDestination.onDevice,
  if (downloaderEnabled) AppDestination.requests,
];

/// [requested] when visible, otherwise Library.
AppDestination resolveDestination(
  AppDestination requested,
  List<AppDestination> visible,
) => visible.contains(requested) ? requested : AppDestination.library;
