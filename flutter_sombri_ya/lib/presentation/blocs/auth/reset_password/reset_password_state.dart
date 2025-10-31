import 'package:equatable/equatable.dart';

class ResetPasswordState extends Equatable {
  final bool loading;
  final String? success;
  final String? error;

  const ResetPasswordState({
    this.loading = false,
    this.success,
    this.error,
  });

  ResetPasswordState copyWith({
    bool? loading,
    String? success,
    String? error,
  }) {
    return ResetPasswordState(
      loading: loading ?? this.loading,
      success: success,
      error: error,
    );
  }

  factory ResetPasswordState.initial() => const ResetPasswordState();

  @override
  List<Object?> get props => [loading, success, error];
}
