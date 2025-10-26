import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatUserSent extends ChatEvent {
  final String text;
  final bool stream;
  const ChatUserSent(this.text, {this.stream = true});
  @override
  List<Object?> get props => [text, stream];
}

class ChatChunkArrived extends ChatEvent {
  final String chunk;
  const ChatChunkArrived(this.chunk);
  @override
  List<Object?> get props => [chunk];
}

class ChatStreamEnded extends ChatEvent {
  const ChatStreamEnded();
}

class ChatStopRequested extends ChatEvent {
  const ChatStopRequested();
}

class ChatCleared extends ChatEvent {
  const ChatCleared();
}
