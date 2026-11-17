import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// One action shown in an [ActionBar].
class BarAction {
  const BarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.progress,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;

  /// Null disables the action.
  final VoidCallback? onPressed;

  /// Determinate progress 0..1 shown in place while the action runs
  /// (e.g. a download). Use a negative value for indeterminate.
  final double? progress;

  /// Destructive actions only go in the overflow and are coloured as such.
  final bool isDestructive;
}

/// The book's actions in three tiers: one filled primary, up to three
/// labelled secondaries, and everything else in an overflow menu.
///
/// Secondaries share the row equally and put the label under the icon, so
/// long translations wrap instead of pushing buttons off screen.
class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.primary,
    this.secondary = const [],
    this.overflow = const [],
  }) : assert(secondary.length <= 3, 'At most three secondary actions');

  final BarAction primary;
  final List<BarAction> secondary;
  final List<BarAction> overflow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrimaryButton(action: primary),
        if (secondary.isNotEmpty || overflow.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final action in secondary)
                Expanded(child: _SecondaryButton(action: action)),
              if (overflow.isNotEmpty)
                MenuAnchor(
                  alignmentOffset: const Offset(-160, 0),
                  menuChildren: [
                    for (final action in overflow)
                      MenuItemButton(
                        leadingIcon: Icon(
                          action.icon,
                          color: action.isDestructive ? scheme.error : null,
                        ),
                        onPressed: action.onPressed,
                        child: Text(
                          action.label,
                          style:
                              action.isDestructive
                                  ? TextStyle(color: scheme.error)
                                  : null,
                        ),
                      ),
                  ],
                  builder:
                      (context, controller, _) => _SecondaryButton(
                        action: BarAction(
                          icon: Icons.more_horiz_rounded,
                          label: l10n.moreActions,
                          onPressed:
                              () =>
                                  controller.isOpen
                                      ? controller.close()
                                      : controller.open(),
                        ),
                        compact: true,
                      ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.action});
  final BarAction action;

  @override
  Widget build(BuildContext context) {
    final progress = action.progress;
    final busy = progress != null;
    return FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      onPressed: busy ? null : action.onPressed,
      icon:
          busy
              ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: progress < 0 ? null : progress,
                ),
              )
              : Icon(action.icon),
      label: Text(action.label),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.action, this.compact = false});
  final BarAction action;

  /// The overflow button: icon only visually, label kept for tooltips and
  /// screen readers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final progress = action.progress;

    final icon =
        progress != null
            ? SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: progress < 0 ? null : progress,
              ),
            )
            : Icon(action.icon, color: scheme.primary);

    final child = InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: progress != null ? null : action.onPressed,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 64, minWidth: compact ? 56 : 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final enabled = action.onPressed != null && progress == null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: action.label,
      // Children are excluded, so the tap action is re-exposed here.
      onTap: enabled ? action.onPressed : null,
      excludeSemantics: true,
      child: compact ? Tooltip(message: action.label, child: child) : child,
    );
  }
}
