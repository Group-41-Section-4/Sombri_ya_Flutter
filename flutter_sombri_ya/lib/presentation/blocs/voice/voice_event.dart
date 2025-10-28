import 'package:equatable/equatable.dart';

abstract class VoiceEvent extends Equatable {
  const VoiceEvent();
  @override
  List<Object?> get props => [];
}

class VoiceInitRequested extends VoiceEvent {
  final String localeId;
  const VoiceInitRequested({this.localeId = 'es_CO'});
}

class VoiceStartRequested extends VoiceEvent {
  const VoiceStartRequested();
}

class VoiceStopRequested extends VoiceEvent {
  const VoiceStopRequested();
}

class VoicePartialResult extends VoiceEvent {
  final String transcript;
  const VoicePartialResult(this.transcript);
  @override
  List<Object?> get props => [transcript];
}

class VoiceClearIntent extends VoiceEvent {
  const VoiceClearIntent();
}
