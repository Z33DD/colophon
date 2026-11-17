import 'package:calibre_web_companion/core/navigation/app_route.dart';
import 'package:calibre_web_companion/features/me/presentation/pages/me_page.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in user's avatar in every top-level app bar. Opens the
/// account page: stats, Settings, shelves, switching and adding accounts.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final username =
        GetIt.instance<SharedPreferences>().getString('username') ?? '';
    final initial =
        username.trim().isEmpty ? '?' : username.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: l10n.account,
        onPressed:
            () => Navigator.of(context).push(AppRoute.page(const MePage())),
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: scheme.surfaceContainerLowest,
          foregroundColor: scheme.primary,
          child: Text(
            initial,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
