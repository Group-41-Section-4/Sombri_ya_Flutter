import 'package:equatable/equatable.dart';

abstract class RentEvent extends Equatable {
  const RentEvent();
  @override
  List<Object?> get props => [];
}

class RentInit extends RentEvent {
  const RentInit();
}

class RentStartWithQr extends RentEvent {
  final String rawQr;
  const RentStartWithQr(this.rawQr);
  @override
  List<Object?> get props => [rawQr];
}

class RentStartWithNfc extends RentEvent {
  final String uid;
  const RentStartWithNfc(this.uid);
  @override
  List<Object?> get props => [uid];
}

class RentClearMessage extends RentEvent {
  const RentClearMessage();
}

class RentRefreshActive extends RentEvent {
  const RentRefreshActive();
}
