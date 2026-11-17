import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last reading percentage (0-100) per book, recorded on this device
/// when a reader closes. Lists use it for the progress stamp and book
/// details for "Continue · 64%".
///
/// It is a summary for display only: the reader's own position (EPUB CFI,
/// PDF/CBZ page) and KOReader/WebDAV sync stay the source of truth.
class ReadingProgressIndex {
  ReadingProgressIndex(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'reading_percent_index';

  Map<String, double> _read() {
    try {
      final raw = jsonDecode(_prefs.getString(_key) ?? '{}');
      return {
        for (final MapEntry(:key, :value) in (raw as Map).entries)
          if (value is num) key as String: value.toDouble(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Percentage for [uuid], or null when the book was never opened here.
  double? percentFor(String uuid) => _read()[uuid];

  /// Whole percentage worth showing: started but not finished.
  int? stampPercentFor(String uuid) {
    final p = percentFor(uuid);
    if (p == null || p < 1 || p >= 98) return null;
    return p.round();
  }

  Future<void> record(String uuid, double percent) async {
    final all = _read()..[uuid] = percent.clamp(0, 100).toDouble();
    await _prefs.setString(_key, jsonEncode(all));
  }
}
