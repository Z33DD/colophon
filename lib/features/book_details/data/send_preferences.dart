import 'package:shared_preferences/shared_preferences.dart';

/// How books are sent to an e-reader.
enum SendMethod { browser, email }

/// The last send choices, so the dialog opens the way the user left it
/// instead of resetting to Browser + Kobo every time.
class SendPreferences {
  const SendPreferences({
    this.method = SendMethod.browser,
    this.kindle = false,
    this.format,
  });

  final SendMethod method;

  /// Kindle when true, Kobo otherwise (browser transfer only).
  final bool kindle;

  /// Last format sent by email, lower case; null until first send.
  final String? format;

  static const _methodKey = 'send_method';
  static const _deviceKey = 'send_device';
  static const _formatKey = 'send_format';

  static SendPreferences load(SharedPreferences prefs) => SendPreferences(
    method:
        prefs.getString(_methodKey) == SendMethod.email.name
            ? SendMethod.email
            : SendMethod.browser,
    kindle: prefs.getString(_deviceKey) == 'kindle',
    format: prefs.getString(_formatKey),
  );

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setString(_methodKey, method.name);
    await prefs.setString(_deviceKey, kindle ? 'kindle' : 'kobo');
    if (format != null) await prefs.setString(_formatKey, format!);
  }

  /// The remembered format when the book has it, else EPUB, else the
  /// book's first format.
  String formatFor(List<String> bookFormats) {
    final formats = [for (final f in bookFormats) f.toLowerCase()];
    if (format != null && formats.contains(format)) return format!;
    if (formats.contains('epub')) return 'epub';
    return formats.isNotEmpty ? formats.first : 'epub';
  }
}
