import 'dart:async';

import 'package:calibre_web_companion/core/di/injection_container.dart';
import 'package:calibre_web_companion/core/navigation/app_route.dart';
import 'package:calibre_web_companion/core/services/api_service.dart';
import 'package:calibre_web_companion/core/utils/latest_only.dart';
import 'package:calibre_web_companion/features/book_view/data/datasources/vocabulary_remote_datasource.dart';
import 'package:calibre_web_companion/features/book_view/data/models/library_filter.dart';
import 'package:calibre_web_companion/features/book_view/data/repositories/book_view_repository.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// What the user searched for, and which field it must match.
typedef LibrarySearch = ({String query, SearchScope scope});

/// Full-screen library search with typed suggestions (title, author,
/// series, tag). Pops a [LibrarySearch], or null when dismissed.
class SearchDialog extends StatefulWidget {
  final String? initialQuery;

  const SearchDialog({super.key, this.initialQuery});

  /// Opens the search view and returns the chosen search.
  static Future<LibrarySearch?> open(
    BuildContext context, {
    String? initialQuery,
  }) => Navigator.of(context).push<LibrarySearch>(
    AppRoute(
      fullscreenDialog: true,
      builder: (_) => SearchDialog(initialQuery: initialQuery),
    ),
  );

  @override
  SearchDialogState createState() => SearchDialogState();
}

class _Suggestion {
  final String value;
  // null = book title
  final VocabularyType? type;
  const _Suggestion(this.value, this.type);
}

class SearchDialogState extends State<SearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final VocabularyRemoteDataSource _vocab = VocabularyRemoteDataSource(
    apiService: getIt<ApiService>(),
  );

  Timer? _debounce;
  final _latest = LatestOnly();
  bool _loading = false;
  List<_Suggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {}); // shows or hides the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _fetch(text));
  }

  Future<void> _fetch(String text) async {
    final query = text.trim();
    if (query.length < 2) {
      if (mounted) setState(() => _suggestions = const []);
      return;
    }

    setState(() => _loading = true);
    // A slower response for an earlier keystroke must not win.
    final results = await _latest.run(
      () => Future.wait([
        _suggestTitles(query),
        _vocab.suggest(VocabularyType.authors, query),
        _vocab.suggest(VocabularyType.series, query),
        _vocab.suggest(VocabularyType.tags, query),
      ]),
    );
    if (!mounted || results == null) return;

    final merged = <_Suggestion>[
      ...results[0].take(4).map((v) => _Suggestion(v, null)),
      ...results[1].take(4).map((v) => _Suggestion(v, VocabularyType.authors)),
      ...results[2].take(4).map((v) => _Suggestion(v, VocabularyType.series)),
      ...results[3].take(4).map((v) => _Suggestion(v, VocabularyType.tags)),
    ];

    setState(() {
      _loading = false;
      _suggestions = merged;
    });
  }

  // There is no title vocabulary endpoint, so search books and keep the
  // ones whose title matches (#207).
  Future<List<String>> _suggestTitles(String query) async {
    try {
      final books = await getIt<BookViewRepository>().fetchBooks(
        offset: 0,
        limit: 20,
        searchQuery: query,
      );
      final needle = query.toLowerCase();
      final seen = <String>{};
      return books
          .map((b) => b.title)
          .where((t) => t.toLowerCase().contains(needle) && seen.add(t))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _submit(String value, [SearchScope scope = SearchScope.any]) {
    final query = value.trim();
    if (query.isEmpty) return;
    Navigator.of(context).pop<LibrarySearch>((query: query, scope: scope));
  }

  static SearchScope _scopeFor(VocabularyType? type) => switch (type) {
    null => SearchScope.title,
    VocabularyType.authors => SearchScope.author,
    VocabularyType.series => SearchScope.series,
    VocabularyType.tags => SearchScope.tag,
    VocabularyType.publishers => SearchScope.any,
  };

  IconData _iconFor(VocabularyType? type) {
    switch (type) {
      case null:
        return Icons.menu_book_rounded;
      case VocabularyType.authors:
        return Icons.person_rounded;
      case VocabularyType.series:
        return Icons.bookmark_rounded;
      case VocabularyType.tags:
        return Icons.label_rounded;
      case VocabularyType.publishers:
        return Icons.business_rounded;
    }
  }

  String _labelFor(VocabularyType? type, AppLocalizations localizations) {
    switch (type) {
      case null:
        return localizations.title;
      case VocabularyType.authors:
        return localizations.author;
      case VocabularyType.series:
        return localizations.series;
      case VocabularyType.tags:
        return localizations.tags;
      case VocabularyType.publishers:
        return localizations.publisher;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: localizations.enterTitleAuthorOrTags,
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: _submit,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: localizations.clearSearch,
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _controller.clear();
                setState(() => _suggestions = const []);
              },
            ),
        ],
        bottom:
            _loading
                ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(minHeight: 2),
                )
                : null,
      ),
      body: ListView.builder(
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: Icon(_iconFor(suggestion.type)),
            title: Text(
              suggestion.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_labelFor(suggestion.type, localizations)),
            onTap: () => _submit(suggestion.value, _scopeFor(suggestion.type)),
          );
        },
      ),
    );
  }
}
