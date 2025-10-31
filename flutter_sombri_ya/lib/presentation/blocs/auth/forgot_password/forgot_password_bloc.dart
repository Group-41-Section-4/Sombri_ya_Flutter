import 'package:flutter_bloc/flutter_bloc.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';
import '../../../../data/repositories/auth_repository.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository repo;

  ForgotPasswordBloc({required this.repo}) : super(ForgotPasswordState.initial()) {
    on<ForgotPasswordSubmitted>(_onSubmit);
    on<ForgotPasswordClearMessage>(_onClear);
  }

  Future<void> _onSubmit(
      ForgotPasswordSubmitted event,
      Emitter<ForgotPasswordState> emit,
      ) async {
    final email = event.email.trim();

    if (email.isEmpty) {
      emit(state.copyWith(error: 'Ingresa tu correo'));
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      emit(state.copyWith(error: 'Correo inválido'));
      return;
    }

    emit(const ForgotPasswordState(loading: true));

    try {
      await repo.requestPasswordReset(email);
      emit(const ForgotPasswordState(success: 'Te enviamos un correo con instrucciones'));
    } catch (e) {
      emit(ForgotPasswordState(error: 'No pudimos procesar la solicitud: $e'));
    }
  }

  void _onClear(
      ForgotPasswordClearMessage event,
      Emitter<ForgotPasswordState> emit,
      ) {
    emit(ForgotPasswordState.initial());
  }
}
