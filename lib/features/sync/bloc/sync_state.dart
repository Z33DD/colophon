import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/sync/data/models/sync_filter.dart';
import 'package:equatable/equatable.dart';

enum SyncStatus {
  initial,
  idle,
  scanning,
  preview,
  syncing,
  paused,
  completed,
  canceled,
  error,

  /// The scan finished but no book matched the sync filter.
  nothingToSync,

  /// Sync needs a default download folder first.
  needsDownloadFolder,
}

/// Why sync skipped a book instead of downloading it. Shown per item so a
/// skip is not mistaken for a failure.
enum SyncSkipReason { noMatchingFormat, noFormats }

class SyncQueueItem extends Equatable {
  static const pending = 'pending';
  static const downloading = 'downloading';
  static const done = 'done';
  static const error = 'error';
  static const skipped = 'skipped';

  final BookViewModel book;

  /// One of [pending], [downloading], [done], [error], [skipped].
  final String status;

  /// Set when [status] is [skipped].
  final SyncSkipReason? skipReason;

  const SyncQueueItem({
    required this.book,
    this.status = pending,
    this.skipReason,
  });

  SyncQueueItem copyWith({String? status, SyncSkipReason? skipReason}) {
    return SyncQueueItem(
      book: book,
      status: status ?? this.status,
      skipReason: skipReason ?? this.skipReason,
    );
  }

  @override
  List<Object?> get props => [book, status, skipReason];
}

class SyncState extends Equatable {
  final SyncStatus status;
  final List<SyncQueueItem> queue;
  final int totalBooksToCheck;
  final int syncedCount;
  final String? currentBookTitle;
  final double currentProgress;
  final String? errorMessage;
  final SyncFilter filter;
  final List<BookViewModel> previewBooks;

  const SyncState({
    this.status = SyncStatus.initial,
    this.queue = const [],
    this.totalBooksToCheck = 0,
    this.syncedCount = 0,
    this.currentBookTitle,
    this.currentProgress = 0.0,
    this.errorMessage,
    this.filter = const SyncFilter(),
    this.previewBooks = const [],
  });

  SyncState copyWith({
    SyncStatus? status,
    List<SyncQueueItem>? queue,
    int? totalBooksToCheck,
    int? syncedCount,
    String? currentBookTitle,
    double? currentProgress,
    String? errorMessage,
    SyncFilter? filter,
    List<BookViewModel>? previewBooks,
  }) {
    return SyncState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      totalBooksToCheck: totalBooksToCheck ?? this.totalBooksToCheck,
      syncedCount: syncedCount ?? this.syncedCount,
      currentBookTitle: currentBookTitle ?? this.currentBookTitle,
      currentProgress: currentProgress ?? this.currentProgress,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
      previewBooks: previewBooks ?? this.previewBooks,
    );
  }

  @override
  List<Object?> get props => [
    status,
    queue,
    totalBooksToCheck,
    syncedCount,
    currentBookTitle,
    currentProgress,
    errorMessage,
    filter,
    previewBooks,
  ];
}
