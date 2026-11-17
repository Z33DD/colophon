import 'package:calibre_web_companion/core/utils/network_error.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';

/// Turns raw exception text (what `e.toString()` puts in bloc states) into
/// a message a person can act on.
///
/// Known failure kinds (unreachable server, 401/403/404/5xx) get a plain
/// explanation. Text that already reads like a sentence (a translated
/// string, a server's own message) is kept, minus "Exception: " prefixes.
/// Stack-trace-like or type-name text falls back to a generic message;
/// the raw text still goes to the app log.
String humanizeError(String? raw, AppLocalizations l10n) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return l10n.errorUnexpected;
  if (isNetworkErrorMessage(text)) return l10n.errorUnreachable;

  final status = RegExp(r'\b(401|403|404|5\d\d)\b').firstMatch(text)?.group(1);
  switch (status) {
    case '401':
      return l10n.errorUnauthorized;
    case '403':
      return l10n.errorForbidden;
    case '404':
      return l10n.errorNotFound;
    case final s? when s.startsWith('5'):
      return l10n.errorServer;
  }

  // "Exception: Failed to load books: Exception: ..." -> last real part.
  final stripped =
      text.replaceAll(RegExp(r'(\b\w*(Exception|Error):\s*)+'), '').trim();
  final looksTechnical =
      stripped.isEmpty ||
      stripped.contains('#0') ||
      stripped.contains('package:') ||
      RegExp(
        r"Instance of '|Null check|type '.*' is not a subtype",
      ).hasMatch(stripped);
  if (looksTechnical) return l10n.errorUnexpected;
  return stripped;
}
