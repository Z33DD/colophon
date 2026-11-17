import 'package:calibre_web_companion/features/homepage/app_destination.dart';
import 'package:equatable/equatable.dart';

class HomePageState extends Equatable {
  final AppDestination destination;

  const HomePageState({this.destination = AppDestination.library});

  HomePageState copyWith({AppDestination? destination}) =>
      HomePageState(destination: destination ?? this.destination);

  @override
  List<Object?> get props => [destination];
}
