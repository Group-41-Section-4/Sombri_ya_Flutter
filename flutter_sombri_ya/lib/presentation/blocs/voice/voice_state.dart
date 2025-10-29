import 'package:equatable/equatable.dart';
import '../../../domain/voice/voice_intent.dart';

class VoiceState extends Equatable {
  final bool isReady;
  final bool isListening;
  final String transcript;
  final VoiceIntent intent;

  const VoiceState({
    required this.isReady,
    required this.isListening,
    required this.transcript,
    required this.intent,
  });

  factory VoiceState.initial() => const VoiceState(
    isReady: false,
    isListening: false,
    transcript: '',
    intent: VoiceIntent.none,
  );

  VoiceState copyWith({
    bool? isReady,
    bool? isListening,
    String? transcript,
    VoiceIntent? intent,
  }) => VoiceState(
    isReady: isReady ?? this.isReady,
    isListening: isListening ?? this.isListening,
    transcript: transcript ?? this.transcript,
    intent: intent ?? this.intent,
  );

  @override
  List<Object?> get props => [isReady, isListening, transcript, intent];
}
