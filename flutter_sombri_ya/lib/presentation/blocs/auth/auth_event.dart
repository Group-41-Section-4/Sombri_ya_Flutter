import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginWithPasswordSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginWithPasswordSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class LoginWithGoogleRequested extends AuthEvent {
  const LoginWithGoogleRequested();
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String name;
  final String password;
  final bool biometricEnabled;
  const RegisterSubmitted({
    required this.email,
    required this.name,
    required this.password,
    required this.biometricEnabled,
  });

  @override
  List<Object?> get props => [email, name, password, biometricEnabled];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
