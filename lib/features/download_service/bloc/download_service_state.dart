import 'package:calibre_web_companion/features/download_service/data/models/download_config_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_filter_model.dart';
import 'package:calibre_web_companion/features/download_service/data/models/download_service_book_model.dart';
import 'package:equatable/equatable.dart';

enum DownloadServiceTab { search, downloads }

enum DownloadServiceStatus { initial, loading, loaded, error }

class DownloadServiceState extends Equatable {
  final DownloadServiceStatus searchStatus;
  final DownloadServiceStatus downloadStatus;
  final DownloadServiceStatus statusLoadingStatus;
  final List<DownloadServiceBookModel> searchResults;
  final List<DownloadServiceBookModel> books;
  final String? downloadingBookId;
  final bool hasSearched;
  final String? errorMessage;
  final DownloadServiceTab activeTab;
  final DownloadConfigModel config;
  final DownloadFilterModel activeFilter;

  /// Requests the server accepted in this session (book ids).
  final Set<String> queuedRequests;

  /// Requests that failed, with the reason, per book id. Kept apart from
  /// [errorMessage] so one failed request doesn't replace the whole list.
  final Map<String, String> failedRequests;

  const DownloadServiceState({
    this.searchStatus = DownloadServiceStatus.initial,
    this.downloadStatus = DownloadServiceStatus.initial,
    this.statusLoadingStatus = DownloadServiceStatus.initial,
    this.searchResults = const [],
    this.books = const [],
    this.downloadingBookId,
    this.hasSearched = false,
    this.errorMessage,
    this.activeTab = DownloadServiceTab.search,
    this.config = const DownloadConfigModel(),
    this.activeFilter = const DownloadFilterModel(),
    this.queuedRequests = const {},
    this.failedRequests = const {},
  });

  bool get isSearching => searchStatus == DownloadServiceStatus.loading;
  bool get isLoading => statusLoadingStatus == DownloadServiceStatus.loading;
  bool get isDownloading => downloadingBookId != null;

  bool isBookDownloading(String bookId) => downloadingBookId == bookId;

  DownloadServiceState copyWith({
    DownloadServiceStatus? searchStatus,
    DownloadServiceStatus? downloadStatus,
    DownloadServiceStatus? statusLoadingStatus,
    List<DownloadServiceBookModel>? searchResults,
    List<DownloadServiceBookModel>? books,
    String? downloadingBookId,
    bool? hasSearched,
    String? errorMessage,
    DownloadServiceTab? activeTab,
    DownloadConfigModel? config,
    DownloadFilterModel? activeFilter,
    Set<String>? queuedRequests,
    Map<String, String>? failedRequests,
  }) {
    return DownloadServiceState(
      searchStatus: searchStatus ?? this.searchStatus,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      statusLoadingStatus: statusLoadingStatus ?? this.statusLoadingStatus,
      searchResults: searchResults ?? this.searchResults,
      books: books ?? this.books,
      downloadingBookId: downloadingBookId,
      hasSearched: hasSearched ?? this.hasSearched,
      errorMessage: errorMessage,
      activeTab: activeTab ?? this.activeTab,
      config: config ?? this.config,
      activeFilter: activeFilter ?? this.activeFilter,
      queuedRequests: queuedRequests ?? this.queuedRequests,
      failedRequests: failedRequests ?? this.failedRequests,
    );
  }

  @override
  List<Object?> get props => [
    searchStatus,
    downloadStatus,
    statusLoadingStatus,
    searchResults,
    books,
    downloadingBookId,
    hasSearched,
    errorMessage,
    activeTab,
    config,
    activeFilter,
    queuedRequests,
    failedRequests,
  ];
}
