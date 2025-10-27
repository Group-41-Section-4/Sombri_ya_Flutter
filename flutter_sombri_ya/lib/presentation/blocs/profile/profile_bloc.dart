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
        RegExp(
          r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
          caseSensitive: false,
        ).hasMatch(v);
  }

  bool _validPass(String v) {
    v = v.trim();
    if (v.length < 8 || v.length > 64) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(v);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    final hasSpec = RegExp(r'[^\w\s]').hasMatch(v);
    return hasLower && hasUpper && hasDigit && hasSpec;
  }

  Future<void> _onLoad(LoadProfile e, Emitter<ProfileState> emit) async {
    emit(
      state.copyWith(loading: true, successMessage: null, errorMessage: null),
    );
    try {
      final data = await repository.getProfile(e.userId);
      final km = (data['total_pedometer_km'] as num?)?.toDouble() ?? 0.0;
      emit(state.copyWith(loading: false, profile: data, totalDistanceKm: km));
      // add(LoadTotalDistance(data['id']?.toString() ?? e.userId));
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'No se pudo cargar el perfil.',
        ),
      );
    }
  }

  Future<void> _onRefresh(RefreshProfile e, Emitter<ProfileState> emit) async {
    try {
      final data = await repository.getProfile(e.userId);
      final km = (data['total_pedometer_km'] as num?)?.toDouble() ?? 0.0;
      emit(state.copyWith(profile: data, totalDistanceKm: km));
      // add(LoadTotalDistance(data['id']?.toString() ?? e.userId));
    } catch (_) {
      emit(state.copyWith(errorMessage: 'No se pudo actualizar el perfil.'));
    }
  }

  // Future<void> _onLoadDistance(
  //   LoadTotalDistance e,
  //   Emitter<ProfileState> emit,
  // ) async {
  //   try {
  //     final km = await repository.getTotalDistance(e.userId);
  //     emit(state.copyWith(totalDistanceKm: km));
  //   } catch (_) {
  //     /* no crítico */
  //   }
  // }

  Future<void> _onUpdateField(
    UpdateProfileField e,
    Emitter<ProfileState> emit,
  ) async {
    final val = e.newValue.trim();
    final ok = switch (e.fieldKey) {
      'name' => _validName(val),
      'email' => _validEmail(val),
      _ => val.isNotEmpty && val.length <= 100,
    };
    if (!ok) {
      emit(state.copyWith(errorMessage: 'Valor no válido para ${e.fieldKey}.'));
      return;
    }

    final old = Map<String, dynamic>.from(state.profile ?? {});
    final optimistic = Map<String, dynamic>.from(old)..[e.fieldKey] = val;
    emit(
      state.copyWith(
        profile: optimistic,
        successMessage: null,
        errorMessage: null,
      ),
    );

    try {
      final updated = await repository.updateField(
        userId: (state.profile?['id'] ?? e.userId).toString(),
        fieldKey: e.fieldKey,
        newValue: val,
      );
      emit(
        state.copyWith(profile: updated, successMessage: 'Campo actualizado'),
      );
    } catch (_) {
      emit(
        state.copyWith(
          profile: old,
          errorMessage: 'No se pudo actualizar ${e.fieldKey}.',
        ),
      );
    }
  }

  Future<void> _onChangePassword(
    ChangePassword e,
    Emitter<ProfileState> emit,
  ) async {
    final curr = e.currentPassword.trim();
    final next = e.newPassword.trim();
    if (!_validPass(next) || curr.isEmpty) {
      emit(
        state.copyWith(errorMessage: 'La contraseña no cumple los requisitos.'),
      );
      return;
    }
    try {
      await repository.changePassword(
        userId: (state.profile?['id'] ?? e.userId).toString(),
        currentPassword: curr,
        newPassword: next,
      );
      emit(
        state.copyWith(successMessage: 'Contraseña actualizada correctamente.'),
      );
    } catch (_) {
      emit(state.copyWith(errorMessage: 'No se pudo cambiar la contraseña.'));
    }
  }
}
