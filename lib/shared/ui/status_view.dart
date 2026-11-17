import 'package:flutter/material.dart';

/// Full-area state for a list or page: loading, empty, or error.
///
/// One component so every screen says the same thing the same way, and an
/// error is shown here only, never also as a snackbar.
class StatusView extends StatelessWidget {
  const StatusView._({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
    this.isLoading = false,
  });

  /// Nothing to show yet, with an optional way forward (e.g. clear filters).
  const StatusView.empty({
    Key? key,
    required IconData icon,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this._(
         key: key,
         icon: icon,
         title: title,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  /// Something failed. [actionLabel] is usually "Retry".
  const StatusView.error({
    Key? key,
    required String title,
    String? message,
    required String actionLabel,
    required VoidCallback onAction,
    IconData icon = Icons.cloud_off_rounded,
  }) : this._(
         key: key,
         icon: icon,
         title: title,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
         isError: true,
       );

  /// Indeterminate progress with a short label for screen readers.
  const StatusView.loading({Key? key, required String label})
    : this._(
        key: key,
        icon: Icons.hourglass_empty,
        title: label,
        isLoading: true,
      );

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (isLoading) {
      return Center(
        child: Semantics(
          label: title,
          liveRegion: true,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Semantics(
            liveRegion: isError,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: isError ? scheme.error : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: text.titleMedium,
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
