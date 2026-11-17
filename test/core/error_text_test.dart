import 'package:calibre_web_companion/core/utils/error_text.dart';
import 'package:calibre_web_companion/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('network failures explain that the server is unreachable', () {
    // Regression: snackbars showed raw text such as
    // "Exception: ClientException with SocketException: Failed host lookup".
    expect(
      humanizeError(
        'Exception: ClientException with SocketException: Failed host lookup',
        l10n,
      ),
      l10n.errorUnreachable,
    );
  });

  test('HTTP status codes map to their meaning', () {
    expect(humanizeError('Failed to load (401)', l10n), l10n.errorUnauthorized);
    expect(humanizeError('status 403', l10n), l10n.errorForbidden);
    expect(humanizeError('HTTP 404 Not Found', l10n), l10n.errorNotFound);
    expect(humanizeError('Server responded 502', l10n), l10n.errorServer);
  });

  test('exception prefixes are stripped from readable messages', () {
    expect(
      humanizeError('Exception: Book details not available', l10n),
      'Book details not available',
    );
  });

  test('a sentence that starts with "Error" is kept', () {
    expect(humanizeError('Error loading data', l10n), 'Error loading data');
  });

  test('technical noise falls back to a generic message', () {
    expect(
      humanizeError("Null check operator used on a null value", l10n),
      l10n.errorUnexpected,
    );
    expect(
      humanizeError("type 'Null' is not a subtype of type 'String'", l10n),
      l10n.errorUnexpected,
    );
    expect(humanizeError('', l10n), l10n.errorUnexpected);
  });
}
