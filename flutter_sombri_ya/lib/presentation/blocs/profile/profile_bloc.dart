// lib/presentation/blocs/profile/profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import 'package:flutter_sombri_ya/data/repositories/profile_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileState.initial()) {
    on<LoadProfile>(_onLoad);
    on<RefreshProfile>(_onRefresh);
    on<UpdateProfileField>(_onUpdateField);
    on<ChangePassword>(_onChangePassword);
    on<ClearProfileMessages>((e, emit) {
      emit(state.copyWith(successMessage: null, errorMessage: null));
    });
  }

  bool _validName(String v) {
    v = v.trim();
    return v.isNotEmpty &&
        v.length <= 50 &&
        RegExp(r"^[A-Za-zÀ-ÿ\u00f1\u00d1' -]+$").hasMatch(v);
  }

  bool _validEmail(String v) {
    v = v.trim();
    return v.isNotEmpty &&
        v.length <= 254 &&
        RegExp(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
                caseSensitive: false)
            .hasMatch(v);
  }

  bool _validPhone(String v) {
    v = v.trim();
    if (v.isEmpty || v.length > 20) return false;
    final plusCount = RegExp(r'\+').allMatches(v).length;
    if (plusCount > 1) return false;
    if (plusCount == 1 && !v.startsWith('+')) return false;
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 && digits.length <= 15;
  }

  bool _validPass(String v) {
    v = v.trim();
    if (v.length < 8 || v.length > 64) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(v);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    final hasSpec  = RegExp(r'[^\w\s]').hasMatch(v);
    return hasLower && hasUpper && hasDigit && hasSpec;
  }
  
  Future<void> _onLoad(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(loading: true, successMessage: null, errorMessage: null));
    try {
      final data = await repository.getProfile(event.userId);
      emit(state.copyWith(loading: false, profile: data));
    } catch (_) {
      emit(state.copyWith(loading: false, errorMessage: 'No se pudo cargar el perfil.'));
    }
  }

  Future<void> _onRefresh(RefreshProfile event, Emitter<ProfileState> emit) async {
    try {
      final data = await repository.getProfile(event.userId);
      emit(state.copyWith(profile: data));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'No se pudo actualizar el perfil.'));
    }
  }

  Future<void> _onUpdateField(UpdateProfileField event, Emitter<ProfileState> emit) async {
    final val = event.newValue.trim();

    final ok = switch (event.fieldKey) {
      'name'  => _validName(val),
      'email' => _validEmail(val),
      'phone' => _validPhone(val),
      _       => val.isNotEmpty && val.length <= 100,
    };
    if (!ok) {
      emit(state.copyWith(errorMessage: 'Valor no válido para ${event.fieldKey}.'));
      return;
    }

    final old = Map<String, dynamic>.from(state.profile ?? {});
    final optimistic = Map<String, dynamic>.from(old)..[event.fieldKey] = val;
    emit(state.copyWith(profile: optimistic, successMessage: null, errorMessage: null));

    try {
      final updated = await repository.updateField(
        userId: event.userId,
        fieldKey: event.fieldKey,
        newValue: val,
      );
      emit(state.copyWith(profile: updated, successMessage: 'Campo actualizado'));
    } catch (_) {
      emit(state.copyWith(profile: old, errorMessage: 'No se pudo actualizar ${event.fieldKey}.'));
    }
  }

  Future<void> _onChangePassword(ChangePassword event, Emitter<ProfileState> emit) async {
    final curr = event.currentPassword.trim();
    final next = event.newPassword.trim();
    if (!_validPass(next) || curr.isEmpty) {
      emit(state.copyWith(errorMessage: 'La contraseña no cumple los requisitos.'));
      return;
    }
    try {
      await repository.changePassword(
        userId: event.userId,
        currentPassword: curr,
        newPassword: next,
      );
      emit(state.copyWith(successMessage: 'Contraseña actualizada correctamente.'));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'No se pudo cambiar la contraseña.'));
    }
  }
}
