import 'package:calibre_web_companion/core/theme/desk_colors.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/shared/ui/book_stamp.dart';
import 'package:calibre_web_companion/shared/widgets/book_cover_widget.dart';
import 'package:flutter/material.dart';

/// A book jacket at 2:3 with the Circulation Desk treatment: soft shadow,
/// state stamps in the lower right, and a typeset title card when the
/// server has no cover.
///
/// Screen readers hear "title by author" plus each stamp.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    required this.author,
    this.bookId = 0,
    this.coverUrl,
    this.stamps = const [],
    this.onTap,
    this.image,
  });

  final String title;
  final String author;
  final int bookId;
  final String? coverUrl;
  final List<StampKind> stamps;
  final VoidCallback? onTap;

  /// Overrides the network image (tests, local offline covers).
  final Widget? image;

  static const aspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final desk = context.desk;
    final radius = BorderRadius.circular(3);
    final hasCover = image != null || bookId > 0 || (coverUrl ?? '').isNotEmpty;

    return Semantics(
      button: onTap != null,
      label: l10n.coverSemanticLabel(title, author),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: desk.coverShadow,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  child:
                      hasCover
                          ? image ??
                              LayoutBuilder(
                                builder:
                                    (context, box) => BookCoverWidget(
                                      bookId: bookId,
                                      coverUrl: coverUrl,
                                      fit: BoxFit.cover,
                                      // Decode at display size, not the
                                      // server's full-resolution jacket.
                                      decodeWidth:
                                          (box.maxWidth *
                                                  MediaQuery.devicePixelRatioOf(
                                                    context,
                                                  ))
                                              .round(),
                                      fallback: TitleCard(
                                        title: title,
                                        author: author,
                                      ),
                                    ),
                              )
                          : TitleCard(title: title, author: author),
                ),
                if (stamps.isNotEmpty)
                  Positioned(
                    right: 5,
                    bottom: 7,
                    left: 5,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 3,
                      runSpacing: 3,
                      children: [for (final s in stamps) BookStamp(s)],
                    ),
                  ),
                if (onTap != null)
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(onTap: onTap),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Typeset stand-in for a missing cover, so a coverless book is still
/// recognisable in a wall of jackets instead of showing a broken image.
class TitleCard extends StatelessWidget {
  const TitleCard({super.key, required this.title, required this.author});

  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              author,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            Text(
              title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
