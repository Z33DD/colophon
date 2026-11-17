import 'package:calibre_web_companion/features/login/data/session_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'restoring brings back the account an abandoned login overwrote',
    () async {
      // Regression: "Add another account" logged out first, and login writes
      // the new URL and credentials before it knows the login worked.
      SharedPreferences.setMockInitialValues({
        'base_url': 'https://books.example',
        'username': 'alice',
        'password': 'secret',
        'server_type': 'calibreWeb',
        'calibre_web_cookie': 'session=abc',
        'is_sso_session': false,
        'unrelated_setting': 'kept',
      });
      final prefs = await SharedPreferences.getInstance();
      final snapshot = SessionSnapshot.capture(prefs);

      // A login attempt for another server starts writing its own values.
      await prefs.setString('base_url', 'https://other.example');
      await prefs.setString('username', 'bob');
      await prefs.remove('calibre_web_cookie');
      await prefs.setString('calibre_library_id', '2');
      await prefs.setString('unrelated_setting', 'changed');

      await snapshot.restore(prefs);

      expect(prefs.getString('base_url'), 'https://books.example');
      expect(prefs.getString('username'), 'alice');
      expect(prefs.getString('password'), 'secret');
      expect(prefs.getString('calibre_web_cookie'), 'session=abc');
      expect(prefs.getBool('is_sso_session'), isFalse);
      expect(
        prefs.containsKey('calibre_library_id'),
        isFalse,
        reason: 'keys absent before the attempt are removed again',
      );
      expect(
        prefs.getString('unrelated_setting'),
        'changed',
        reason: 'only session keys are restored',
      );
    },
  );
}
