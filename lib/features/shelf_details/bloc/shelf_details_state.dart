import 'package:calibre_web_companion/features/book_view/data/models/book_view_model.dart';
import 'package:calibre_web_companion/features/shelf_details/data/models/shelf_details_model.dart';
import 'package:equatable/equatable.dart';

enum ShelfDetailsStatus { initial, loading, loaded, error }

enum ShelfDetailsActionStatus { initial, loading, success, error }

/// Outcome of a shelf action.
enum ShelfAction {
  bookRemoved,
  bookRemoveFailed,
  edited,
  editFailed,
  deleted,
  deleteFailed,
}

class ShelfDetailsState extends Equatable {
  final ShelfDetailsStatus status;
  final ShelfDetailsModel? currentShelfDetail;
  final String? errorMessage;
  final ShelfDetailsActionStatus actionDetailsStatus;

  /// Which action just finished, so the page can say so in the user's
  /// language. Replaces matching English text such as "deleted".
  final ShelfAction? action;
  final BookViewModel? bookDetails;
  final String? loadingBookId;
  final bool isOpds;
  final bool isLoadingMore;
  final bool hasMoreBooks;
  final int? nextOffset;
  final bool isMagic;
  final String? magicIcon;

  const ShelfDetailsState({
    this.status = ShelfDetailsStatus.initial,
    this.currentShelfDetail,
    this.errorMessage,
    this.actionDetailsStatus = ShelfDetailsActionStatus.initial,
    this.action,
    this.bookDetails,
    this.loadingBookId,
    this.isOpds = false,
    this.isLoadingMore = false,
    this.hasMoreBooks = false,
    this.nextOffset,
    this.isMagic = false,
    this.magicIcon,
  });

  ShelfDetailsState copyWith({
    ShelfDetailsStatus? status,
    ShelfDetailsModel? currentShelfDetail,
    String? errorMessage,
    ShelfDetailsActionStatus? actionDetailsStatus,
    ShelfAction? action,
    BookViewModel? bookDetails,
    String? loadingBookId,
    bool? isOpds,
    bool? isLoadingMore,
    bool? hasMoreBooks,
    int? nextOffset,
    bool? isMagic,
    String? magicIcon,
  }) {
    return ShelfDetailsState(
      status: status ?? this.status,
      currentShelfDetail: currentShelfDetail ?? this.currentShelfDetail,
      errorMessage: errorMessage,
      actionDetailsStatus: actionDetailsStatus ?? this.actionDetailsStatus,
      action: action,
      bookDetails: bookDetails ?? this.bookDetails,
      loadingBookId: loadingBookId ?? this.loadingBookId,
      isOpds: isOpds ?? this.isOpds,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreBooks: hasMoreBooks ?? this.hasMoreBooks,
      nextOffset: nextOffset ?? this.nextOffset,
      isMagic: isMagic ?? this.isMagic,
      magicIcon: magicIcon ?? this.magicIcon,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentShelfDetail,
    errorMessage,
    actionDetailsStatus,
    action,
    bookDetails,
    loadingBookId,
    isOpds,
    isLoadingMore,
    hasMoreBooks,
    nextOffset,
    isMagic,
    magicIcon,
  ];
}
