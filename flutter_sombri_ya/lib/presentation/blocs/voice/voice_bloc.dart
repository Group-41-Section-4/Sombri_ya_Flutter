import 'package:bloc/bloc.dart';

import '../../../core/services/voice_command_service.dart';
import '../../../domain/voice/parse_intent.dart';
import '../../../domain/voice/voice_intent.dart';

import 'voice_event.dart';
import 'voice_state.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final VoiceCommandService service;

  VoiceBloc(this.service) : super(VoiceState.initial()) {
    on<VoiceInitRequested>(_onInit);
    on<VoiceStartRequested>(_onStart);
    on<VoiceStopRequested>(_onStop);
    on<VoicePartialResult>(_onPartial);
    on<VoiceClearIntent>(_onClear);
  }

  Future<void> _onInit(VoiceInitRequested e, Emitter<VoiceState> emit) async {
    final ok = await service.init(localeId: e.localeId);
    emit(state.copyWith(isReady: ok));
  }

  Future<void> _onStart(VoiceStartRequested e, Emitter<VoiceState> emit) async {
    if (!state.isReady) {
      final ok = await service.init(localeId: 'es_CO');
      emit(state.copyWith(isReady: ok));
    }

    emit(
      state.copyWith(
        isListening: true,
        transcript: '',
        intent: VoiceIntent.none,
      ),
    );

    await service.start(
      localeId: 'es_CO',
      onResult: (t) => add(VoicePartialResult(t)),
    );
  }

  Future<void> _onStop(VoiceStopRequested e, Emitter<VoiceState> emit) async {
    await service.stop();
    emit(state.copyWith(isListening: false));
  }

  void _onPartial(VoicePartialResult e, Emitter<VoiceState> emit) {
    final intent = parseIntent(e.transcript);
    emit(state.copyWith(transcript: e.transcript, intent: intent));
  }

  void _onClear(VoiceClearIntent e, Emitter<VoiceState> emit) {
    emit(state.copyWith(intent: VoiceIntent.none));
  }
}
