import 'package:calibre_web_companion/core/navigation/app_route.dart';
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
class LibrarySearchField extends StatelessWidget {
  const LibrarySearchField({super.key, required this.state});

  final BookViewState state;

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

    return Semantics(
      button: true,
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

    // One row: filters, then the sort control naming the active order.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        spacing: 8,
        children: [
          if (state.canFilter) ...[
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
          _SortChip(state: state),
        ],
      ),
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

/// Sort as a chip naming the active order, with a menu that marks it.
/// Filtered lists come in server order and can't be re-sorted.
class _SortChip extends StatelessWidget {
  const _SortChip({required this.state});

  final BookViewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    if (!state.filter.isAll || state.isOpds) {
      return Chip(
        avatar: const Icon(Icons.swap_vert_rounded),
        label: Text(l10n.serverOrder),
      );
    }

    return MenuAnchor(
      menuChildren: [
        for (final MapEntry(:key, :value) in options.entries)
          MenuItemButton(
            leadingIcon:
                key == current
                    ? const Icon(Icons.check_rounded)
                    : const SizedBox(width: 24),
            onPressed: () {
              final bloc = context.read<BookViewBloc>();
              if (key == 'series:folders') {
                bloc.add(const EnterSeriesFolderMode());
                return;
              }
              final parts = key.split(':');
              bloc.add(ChangeSort(sortBy: parts[0], sortOrder: parts[1]));
            },
            child: Text(value),
          ),
      ],
      builder:
          (context, controller, _) => ActionChip(
            avatar: const Icon(Icons.swap_vert_rounded),
            tooltip: l10n.sorting,
            label: Text(options[current] ?? l10n.newestFirst),
            onPressed:
                () =>
                    controller.isOpen ? controller.close() : controller.open(),
          ),
    );
  }
}
