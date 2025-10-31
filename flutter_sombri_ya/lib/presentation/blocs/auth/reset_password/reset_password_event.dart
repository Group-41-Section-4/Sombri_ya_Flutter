import 'package:equatable/equatable.dart';

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();
  @override
  List<Object?> get props => [];
}

class ResetPasswordSubmitted extends ResetPasswordEvent {
  final String userId;
  final String token;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordSubmitted({
    required this.userId,
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [userId, token, newPassword, confirmPassword];
}

class ResetPasswordClearMessage extends ResetPasswordEvent {
  const ResetPasswordClearMessage();
}
