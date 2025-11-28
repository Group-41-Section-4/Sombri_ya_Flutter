import 'package:equatable/equatable.dart';

abstract class HelpEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HelpStarted extends HelpEvent {}

class HelpRefreshed extends HelpEvent {}
