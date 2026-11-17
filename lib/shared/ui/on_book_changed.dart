import 'dart:async';

import 'package:calibre_web_companion/core/services/library_events.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// Calls [onChanged] for every [BookChanged] while this widget is mounted.
/// Lets a list screen refresh when a book it shows changed elsewhere.
class OnBookChanged extends StatefulWidget {
  const OnBookChanged({
    super.key,
    required this.onChanged,
    required this.child,
  });

  final void Function(BuildContext context, BookChanged event) onChanged;
  final Widget child;

  @override
  State<OnBookChanged> createState() => _OnBookChangedState();
}

class _OnBookChangedState extends State<OnBookChanged> {
  StreamSubscription<BookChanged>? _subscription;

  @override
  void initState() {
    super.initState();
    if (GetIt.instance.isRegistered<LibraryEvents>()) {
      _subscription = GetIt.instance<LibraryEvents>().stream.listen((event) {
        if (mounted) widget.onChanged(context, event);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
