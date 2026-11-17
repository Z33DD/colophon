import 'package:calibre_web_companion/features/homepage/app_destination.dart';
import 'package:equatable/equatable.dart';

abstract class HomePageEvent extends Equatable {
  const HomePageEvent();

  @override
  List<Object?> get props => [];
}

/// Show [destination]. The shell falls back to Library when it is hidden.
class SelectDestination extends HomePageEvent {
  final AppDestination destination;

  const SelectDestination(this.destination);

  @override
  List<Object?> get props => [destination];
}
