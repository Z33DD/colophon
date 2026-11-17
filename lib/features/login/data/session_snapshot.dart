import 'package:shared_preferences/shared_preferences.dart';

/// A copy of the signed-in account's session preferences.
///
/// Login writes the new URL, credentials and cookies to preferences before
/// it knows whether the login works. To add a second account without losing
/// the first, capture a snapshot before showing the login screen and
/// [restore] it if the user backs out or the login fails.
class SessionSnapshot {
  SessionSnapshot._(this._values);

  /// Every preference key that identifies or authenticates the current
  /// session. Keep in sync with LoginRemoteDataSource and MeRemoteDataSource.
  static const keys = [
    'base_url',
    'username',
    'password',
    'server_type',
    'calibre_web_session',
    'calibre_web_cookie',
    'user_agent',
    'calibre_library_id',
    'calibre_library_map',
    'is_sso_session',
  ];

  /// Value per key; null means the key was absent.
  final Map<String, Object?> _values;

  static SessionSnapshot capture(SharedPreferences prefs) =>
      SessionSnapshot._({for (final key in keys) key: prefs.get(key)});

  /// Writes the captured values back and removes keys that did not exist
  /// when the snapshot was taken. Other preferences are left untouched.
  Future<void> restore(SharedPreferences prefs) async {
    for (final MapEntry(:key, :value) in _values.entries) {
      switch (value) {
        case null:
          await prefs.remove(key);
        case final String v:
          await prefs.setString(key, v);
        case final bool v:
          await prefs.setBool(key, v);
        case final int v:
          await prefs.setInt(key, v);
        case final double v:
          await prefs.setDouble(key, v);
        case final List<String> v:
          await prefs.setStringList(key, v);
      }
    }
  }
}
