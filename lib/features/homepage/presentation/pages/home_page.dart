import 'package:calibre_web_companion/core/navigation/app_route.dart';
import 'package:calibre_web_companion/features/book_view/presentation/pages/book_view_page.dart';
import 'package:calibre_web_companion/features/discover/presentation/pages/discover_page.dart';
import 'package:calibre_web_companion/features/download_service/presentation/pages/download_service_page.dart';
import 'package:calibre_web_companion/features/homepage/app_destination.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_bloc.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_event.dart';
import 'package:calibre_web_companion/features/homepage/bloc/homepage_state.dart';
import 'package:calibre_web_companion/features/login_settings/presentation/pages/connection_diagnostics_page.dart';
import 'package:calibre_web_companion/features/me/presentation/widgets/account_button.dart';
import 'package:calibre_web_companion/features/offline/cubit/connectivity_cubit.dart';
import 'package:calibre_web_companion/features/offline/presentation/pages/offline_library_page.dart';
import 'package:calibre_web_companion/features/opds_browser/presentation/pages/opds_feed_page.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_state.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Width at which navigation moves from a bottom bar to a side rail.
const _railBreakpoint = 600.0;

/// The app shell: top-level destinations in a bottom bar (phones) or a
/// navigation rail (600dp and wider).
///
/// Destinations live in an IndexedStack so each keeps its scroll position
/// and loaded data while you switch, and across going offline and back.
/// Going offline no longer swaps in a separate app: a banner appears,
/// server-only destinations are disabled, and On device stays usable.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen:
          (previous, current) =>
              previous.isDownloaderEnabled != current.isDownloaderEnabled,
      builder: (context, settings) {
        final serverType = GetIt.instance<SharedPreferences>().getString(
          'server_type',
        );
        final visible = visibleDestinations(
          serverType: serverType,
          downloaderEnabled: settings.isDownloaderEnabled,
        );
        return HomeShell(
          visible: visible,
          offline:
              context.watch<ConnectivityCubit>().state ==
              ConnectivityStatus.offline,
          pageFor: (destination) => _page(destination, serverType),
        );
      },
    );
  }

  static Widget _page(AppDestination destination, String? serverType) =>
      switch (destination) {
        AppDestination.library =>
          serverType == 'opds' ? const OpdsFeedPage() : const BookViewPage(),
        AppDestination.discover => const DiscoverPage(),
        AppDestination.onDevice => const OnDevicePage(),
        AppDestination.requests => const DownloadServicePage(),
      };
}

/// The shell without server lookups, so it can be tested with stub pages.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.visible,
    required this.pageFor,
    this.offline = false,
  });

  final List<AppDestination> visible;

  /// Server unreachable: show the banner and disable server destinations.
  final bool offline;
  final Widget Function(AppDestination) pageFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<HomePageBloc, HomePageState>(
      builder: (context, home) {
        var current = resolveDestination(home.destination, visible);
        // Offline, a server destination can't load: show the books on the
        // device instead. The requested destination is kept in the bloc, so
        // it comes back by itself when the connection returns.
        if (offline && current.needsServer) current = AppDestination.onDevice;
        final index = visible.indexOf(current);

        void select(int i) =>
            context.read<HomePageBloc>().add(SelectDestination(visible[i]));

        final stack = IndexedStack(
          index: index,
          children: [for (final d in visible) pageFor(d)],
        );
        // The banner sits under the content, above the navigation, so it
        // never pushes the destination's app bar out of the status bar.
        final body = Column(
          children: [
            Expanded(child: stack),
            if (offline) const _OfflineBanner(),
          ],
        );

        return PopScope(
          // Back from another destination returns to Library first.
          canPop: current == AppDestination.library,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              context.read<HomePageBloc>().add(
                const SelectDestination(AppDestination.library),
              );
            }
          },
          child: LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth >= _railBreakpoint) {
                return Scaffold(
                  body: Row(
                    children: [
                      NavigationRail(
                        selectedIndex: index,
                        onDestinationSelected: select,
                        destinations: [
                          for (final d in visible)
                            NavigationRailDestination(
                              icon: Icon(_icon(d)),
                              selectedIcon: Icon(_selectedIcon(d)),
                              label: Text(_label(d, l10n)),
                              disabled: offline && d.needsServer,
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1, thickness: 0),
                      Expanded(child: body),
                    ],
                  ),
                );
              }
              return Scaffold(
                body: body,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: select,
                  destinations: [
                    for (final d in visible)
                      NavigationDestination(
                        icon: Icon(_icon(d)),
                        selectedIcon: Icon(_selectedIcon(d)),
                        label: _label(d, l10n),
                        enabled: !(offline && d.needsServer),
                        tooltip:
                            offline && d.needsServer ? l10n.needsServer : null,
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static IconData _icon(AppDestination d) => switch (d) {
    AppDestination.library => Icons.auto_stories_outlined,
    AppDestination.discover => Icons.explore_outlined,
    AppDestination.onDevice => Icons.download_for_offline_outlined,
    AppDestination.requests => Icons.move_to_inbox_outlined,
  };

  static IconData _selectedIcon(AppDestination d) => switch (d) {
    AppDestination.library => Icons.auto_stories,
    AppDestination.discover => Icons.explore,
    AppDestination.onDevice => Icons.download_for_offline,
    AppDestination.requests => Icons.move_to_inbox,
  };

  static String _label(AppDestination d, AppLocalizations l10n) => switch (d) {
    AppDestination.library => l10n.navLibrary,
    AppDestination.discover => l10n.discover,
    AppDestination.onDevice => l10n.navOnDevice,
    AppDestination.requests => l10n.navRequests,
  };
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: SizedBox(
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.offlineShellBanner,
                    style: TextStyle(color: scheme.onTertiaryContainer),
                  ),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).push(AppRoute.page(const ConnectionDiagnosticsPage())),
                  child: Text(l10n.offlineDiagnose),
                ),
                TextButton(
                  onPressed: () => context.read<ConnectivityCubit>().recheck(),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Books stored on this device, available online and offline.
class OnDevicePage extends StatelessWidget {
  const OnDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navOnDevice),
        actions: const [AccountButton()],
      ),
      body: const OfflineLibraryPage(),
    );
  }
}
