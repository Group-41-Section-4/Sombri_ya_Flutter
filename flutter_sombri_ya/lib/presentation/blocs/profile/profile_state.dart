import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final bool loading;
  final Map<String, dynamic>? profile;
  final double? totalDistanceKm;
  final String? successMessage;
  final String? errorMessage;

  const ProfileState({
    required this.loading,
    required this.profile,
    this.totalDistanceKm,
    this.successMessage,
    this.errorMessage,
  });

  factory ProfileState.initial() =>
      const ProfileState(loading: false, profile: null);

  ProfileState copyWith({
    bool? loading,
    Map<String, dynamic>? profile,
    double? totalDistanceKm,
    String? successMessage,
    String? errorMessage,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      profile: profile ?? this.profile,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [loading, profile, totalDistanceKm, successMessage, errorMessage];
}
