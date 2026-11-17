class BookProgressModel {
  String? bookId;
  int? currentChapterIndex;
  int? currentPageIndex;

  /// How far into the chapter (0-1), or null when only a page is known.
  double? chapterFraction;

  BookProgressModel({
    this.currentChapterIndex,
    this.currentPageIndex,
    this.chapterFraction,
    this.bookId,
  });
}
