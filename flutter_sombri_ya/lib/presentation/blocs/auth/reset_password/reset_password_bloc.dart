import 'package:flutter_bloc/flutter_bloc.dart';
import 'reset_password_event.dart';
import 'reset_password_state.dart';
import '../../../../data/repositories/auth_repository.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final AuthRepository repo;

  ResetPasswordBloc({required this.repo})
      : super(ResetPasswordState.initial()) {
    on<ResetPasswordSubmitted>(_onSubmit);
    on<ResetPasswordClearMessage>(_onClear);
  }

  Future<void> _onSubmit(
      ResetPasswordSubmitted event,
      Emitter<ResetPasswordState> emit,
      ) async {
    final userId = event.userId.trim();
    final token  = event.token.trim();
    final pass   = event.newPassword.trim();
    final confirm= event.confirmPassword.trim();

    if (userId.isEmpty) {
      emit(state.copyWith(error: 'Usuario inválido'));
      return;
    }
    if (token.isEmpty) {
      emit(state.copyWith(error: 'Token inválido o vacío'));
      return;
    }
    if (pass.isEmpty || confirm.isEmpty) {
      emit(state.copyWith(error: 'Completa ambos campos de contraseña'));
      return;
    }
    if (pass != confirm) {
      emit(state.copyWith(error: 'Las contraseñas no coinciden'));
      return;
    }
    if (pass.length < 8) {
      emit(state.copyWith(error: 'La contraseña debe tener al menos 8 caracteres'));
      return;
    }

    emit(const ResetPasswordState(loading: true));

    try {
      await repo.resetPassword(
        userId: userId,
        token: token,
        newPassword: pass,
      );
      emit(const ResetPasswordState(success: 'Contraseña actualizada correctamente'));
    } catch (e) {
      emit(ResetPasswordState(error: 'No se pudo actualizar: $e'));
    }
  }

  void _onClear(
      ResetPasswordClearMessage event,
      Emitter<ResetPasswordState> emit,
      ) {
    emit(ResetPasswordState.initial());
  }
}
