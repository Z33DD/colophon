/// Where the app's colours come from. Persisted by index, so only append.
enum ThemeSource {
  /// Android dynamic colour from the wallpaper.
  system,

  /// Seeded from a colour the user picked.
  custom,

  /// The Circulation Desk identity (default for new installs).
  circulation,
}
