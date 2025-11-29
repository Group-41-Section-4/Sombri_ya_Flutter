import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final bool loading;
  final Map<String, dynamic>? profile;
  final double? totalDistanceKm;
  final int? umbrellaRentals;
  final String? successMessage;
  final String? errorMessage;

  const ProfileState({
    required this.loading,
    required this.profile,
    this.totalDistanceKm,
    this.umbrellaRentals,
    this.successMessage,
    this.errorMessage,
  });

  factory ProfileState.initial() =>
      const ProfileState(loading: false, profile: null, umbrellaRentals: null);

  ProfileState copyWith({
    bool? loading,
    Map<String, dynamic>? profile,
    double? totalDistanceKm,
    int? umbrellaRentals,
    String? successMessage,
    String? errorMessage,
  }) {
    final newProfile = profile ?? this.profile;
    final newUmbrellaRentals =
        umbrellaRentals ??
        (newProfile != null ? (newProfile['umbrellaRentals'] as int?) : null) ??
        this.umbrellaRentals;

    return ProfileState(
      loading: loading ?? this.loading,
      profile: newProfile,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      umbrellaRentals: newUmbrellaRentals,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    profile,
    totalDistanceKm,
    umbrellaRentals,
    successMessage,
    errorMessage,
  ];
}
