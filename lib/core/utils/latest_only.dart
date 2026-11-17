/// Drops results of async calls that a newer call has superseded.
///
/// Typing "tolk" fires a request per keystroke; a slow response for "to"
/// must not replace the suggestions already shown for "tolk".
class LatestOnly {
  int _generation = 0;

  /// Runs [task]; returns null if another [run] started before it finished.
  Future<T?> run<T>(Future<T> Function() task) async {
    final mine = ++_generation;
    final result = await task();
    return mine == _generation ? result : null;
  }
}
