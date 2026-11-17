import 'package:calibre_web_companion/core/navigation/app_route.dart';
import 'package:calibre_web_companion/core/theme/app_theme.dart';
import 'package:calibre_web_companion/core/theme/desk_colors.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_state.dart';
import 'package:calibre_web_companion/features/book_view/data/models/library_filter.dart';
import 'package:calibre_web_companion/features/book_view/presentation/widgets/search_dialog.dart';
import 'package:calibre_web_companion/features/discover/blocs/discover_event.dart';
import 'package:calibre_web_companion/features/discover_details/data/repositories/discover_details_repository.dart';
import 'package:calibre_web_companion/features/shelf_view.dart/presentation/pages/shelf_view_page.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

/// The search pill in the Library app bar. Shows the active search (with
/// its scope) and clears it in one tap.
class LibrarySearchField extends StatelessWidget
    implements PreferredSizeWidget {
  const LibrarySearchField({super.key, required this.state});

  final BookViewState state;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final query = state.searchQuery ?? '';
    final active = query.isNotEmpty;
    final label = switch (state.searchScope) {
      _ when !active => l10n.searchLibraryHint,
      SearchScope.author => l10n.searchScopeAuthor(query),
      SearchScope.series => l10n.searchScopeSeries(query),
      SearchScope.tag => l10n.searchScopeTag(query),
      _ => query,
    };

    Future<void> open() async {
      final search = await SearchDialog.open(context, initialQuery: query);
      if (search != null && context.mounted) {
        context.read<BookViewBloc>().add(
          SearchBooks(search.query, scope: search.scope),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: scheme.surfaceContainerLowest,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color:
                          active ? scheme.onSurface : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (active)
                  IconButton(
                    tooltip: l10n.clearSearch,
                    icon: const Icon(Icons.close_rounded),
                    color: scheme.onSurfaceVariant,
                    onPressed:
                        () => context.read<BookViewBloc>().add(
                          const SearchBooks(''),
                        ),
                  )
                else
                  const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Filter chips and the sort row above the cover wall.
class LibraryFilterBar extends StatelessWidget {
  const LibraryFilterBar({super.key, required this.state});

  final BookViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<BookViewBloc>();
    final filter = state.filter;

    Widget chip(String label, LibraryFilter value) => ChoiceChip(
      label: Text(label),
      selected: filter == value,
      onSelected: (_) => bloc.add(SetLibraryFilter(value)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.canFilter)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              spacing: 8,
              children: [
                chip(l10n.filterAll, LibraryFilter.all),
                chip(l10n.filterUnread, LibraryFilter.unread),
                chip(l10n.filterRead, LibraryFilter.read),
                ActionChip(
                  avatar: const Icon(Icons.collections_bookmark_outlined),
                  label: Text(l10n.filterShelves),
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).push(AppRoute.page(const ShelfViewPage())),
                ),
                FilterChip(
                  label: Text(
                    filter.kind == LibraryFilterKind.format
                        ? l10n.filterFormatValue(filter.format!.toUpperCase())
                        : l10n.filterFormat,
                  ),
                  selected: filter.kind == LibraryFilterKind.format,
                  avatar: const Icon(Icons.arrow_drop_down_rounded),
                  onSelected: (_) => _pickFormat(context),
                ),
              ],
            ),
          ),
        _SortRow(state: state),
      ],
    );
  }

  Future<void> _pickFormat(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<BookViewBloc>();
    final formats = GetIt.instance<DiscoverDetailsRepository>()
        .loadCategories(CategoryType.formats)
        .then((feed) => feed.categories.map((c) => c.title).toList());

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder:
          (sheet) => SafeArea(
            child: FutureBuilder<List<String>>(
              future: formats,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(title: Text(l10n.chooseFormat)),
                    for (final format in snap.data!)
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(format.toUpperCase()),
                        selected: bloc.state.filter.format == format,
                        onTap: () => Navigator.of(sheet).pop(format),
                      ),
                  ],
                );
              },
            ),
          ),
    );
    if (picked != null) {
      bloc.add(SetLibraryFilter(LibraryFilter.format(picked)));
    }
  }
}

/// "Sort: Newest first" with a menu that marks the active order. Filtered
/// lists come in server order and can't be re-sorted.
class _SortRow extends StatelessWidget {
  const _SortRow({required this.state});

  final BookViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final options = <String, String>{
      'added:desc': l10n.newestFirst,
      'title:asc': l10n.titleAZ,
      'title:desc': l10n.titleZA,
      'authors:asc': l10n.authorAZ,
      'authors:desc': l10n.authorZA,
      if (state.canBrowseSeriesFolders)
        'series:folders': l10n.series
      else ...{
        'series:asc': l10n.seriesAZ,
        'series:desc': l10n.seriesZA,
      },
    };
    final current =
        state.seriesFolderMode
            ? 'series:folders'
            : state.sortBy.isEmpty
            ? 'added:desc'
            : '${state.sortBy}:${state.sortOrder}';
    final sortable = state.filter.isAll && !state.isOpds;
    final label =
        sortable
            ? l10n.sortedBy(options[current] ?? l10n.newestFirst)
            : l10n.serverOrder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppTheme.counterStyle.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (sortable)
            PopupMenuButton<String>(
              tooltip: l10n.sorting,
              icon: const Icon(Icons.swap_vert_rounded),
              initialValue: current,
              onSelected: (value) {
                final bloc = context.read<BookViewBloc>();
                if (value == 'series:folders') {
                  bloc.add(const EnterSeriesFolderMode());
                  return;
                }
                final parts = value.split(':');
                bloc.add(ChangeSort(sortBy: parts[0], sortOrder: parts[1]));
              },
              itemBuilder:
                  (_) => [
                    for (final MapEntry(:key, :value) in options.entries)
                      CheckedPopupMenuItem(
                        value: key,
                        checked: key == current,
                        child: Text(value),
                      ),
                  ],
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}

/// "Library" plus the book count and server in condensed caps.
class LibraryTitle extends StatelessWidget {
  const LibraryTitle({super.key, required this.server, this.count});

  final String server;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final desk = context.desk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.navLibrary),
        if (server.isNotEmpty)
          Text(
            (count == null ? server : l10n.libraryCountServer(count!, server))
                .toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.counterStyle.copyWith(
              color: desk.onShellMuted,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}
