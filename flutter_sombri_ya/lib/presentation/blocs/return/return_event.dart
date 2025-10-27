import 'package:equatable/equatable.dart';

abstract class ReturnEvent extends Equatable {
  const ReturnEvent();
  @override
  List<Object?> get props => [];
}

class ReturnInit extends ReturnEvent {
  const ReturnInit();
}

class ReturnWithQr extends ReturnEvent {
  final String rawQr;
  const ReturnWithQr(this.rawQr);
  @override
  List<Object?> get props => [rawQr];
}

class ReturnWithNfc extends ReturnEvent {
  final String uid;
  const ReturnWithNfc(this.uid);
  @override
  List<Object?> get props => [uid];
}

class ReturnClearMessage extends ReturnEvent {
  const ReturnClearMessage(); 
}
