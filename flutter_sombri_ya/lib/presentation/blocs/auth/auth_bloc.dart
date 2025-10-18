import 'package:bloc/bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repo;

  AuthBloc({required this.repo}) : super(const AuthInitial()) {
    on<LoginWithPasswordSubmitted>(_onLoginPassword);
    on<LoginWithGoogleRequested>(_onLoginGoogle);
    on<RegisterSubmitted>(_onRegister);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLoginPassword(
      LoginWithPasswordSubmitted e,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final res = await repo.loginWithPassword(email: e.email, password: e.password);
      emit(AuthAuthenticated(userId: res.userId, token: res.token));
    } catch (err) {
      emit(AuthFailure(err.toString()));
    }
  }

  Future<void> _onLoginGoogle(
      LoginWithGoogleRequested e,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      final res = await repo.loginWithGoogle();
      emit(AuthAuthenticated(userId: res.userId, token: res.token));
    } catch (err) {
      emit(AuthFailure(err.toString()));
    }
  }

  Future<void> _onRegister(
      RegisterSubmitted e,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    try {
      await repo.register(
        email: e.email,
        name: e.name,
        password: e.password,
        biometricEnabled: e.biometricEnabled,
      );
      emit(const RegistrationSuccess());
    } catch (err) {
      emit(AuthFailure(err.toString()));
    }
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    await repo.logout();
    emit(const AuthInitial());
  }
}
