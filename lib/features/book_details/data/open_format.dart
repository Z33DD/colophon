/// Which format to hand to an external reader.
///
/// A format already on the device wins, so opening never downloads a
/// second copy; then EPUB; then the server's first format. The old code
/// always took the first format, which could re-download or open the
/// wrong file (a PDF while an EPUB was already on the phone).
String chooseOpenFormat(
  List<String> serverFormats, {
  Set<String> downloaded = const {},
}) {
  final formats = [for (final f in serverFormats) f.toLowerCase()];
  for (final f in formats) {
    if (downloaded.contains(f)) return f;
  }
  if (downloaded.isNotEmpty && formats.isEmpty) return downloaded.first;
  if (formats.contains('epub')) return 'epub';
  return formats.isNotEmpty ? formats.first : 'epub';
}
