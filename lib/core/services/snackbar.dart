import 'package:calibre_web_companion/core/utils/network_error.dart';
import 'package:flutter/material.dart';

extension SnackBarExtension on BuildContext {
  /// Shows a short message at the bottom of the screen.
  ///
  /// Pass [actionLabel] and [onAction] to offer one follow-up, such as
  /// "Open" after a download or "Undo" after a reset.
  ///
  /// Network errors are dropped here because the offline banner already
  /// reports them; screens must show their own inline error state.
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (isError && isNetworkErrorMessage(message)) return;

    final scheme = Theme.of(this).colorScheme;
    final hasAction = actionLabel != null && onAction != null;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: isError ? TextStyle(color: scheme.onErrorContainer) : null,
          ),
          // Default (inverse surface) for info; error container for errors.
          backgroundColor: isError ? scheme.errorContainer : null,
          // Give people time to reach the action.
          duration:
              hasAction && duration < const Duration(seconds: 6)
                  ? const Duration(seconds: 6)
                  : duration,
          action:
              hasAction
                  ? SnackBarAction(
                    label: actionLabel,
                    onPressed: onAction,
                    textColor: isError ? scheme.onErrorContainer : null,
                  )
                  : null,
        ),
      );
  }
}
