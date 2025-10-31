import 'package:equatable/equatable.dart';

class ForgotPasswordState extends Equatable {
  final bool loading;
  final String? success;
  final String? error;

  const ForgotPasswordState({
    this.loading = false,
    this.success,
    this.error,
  });

  ForgotPasswordState copyWith({
    bool? loading,
    String? success,
    String? error,
  }) {
    return ForgotPasswordState(
      loading: loading ?? this.loading,
      success: success,
      error: error,
    );
  }

  factory ForgotPasswordState.initial() => const ForgotPasswordState();

  @override
  List<Object?> get props => [loading, success, error];
}
