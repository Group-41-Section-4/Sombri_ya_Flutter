import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final bool loading;
  final Map<String, dynamic>? profile;    
  final String? successMessage;
  final String? errorMessage;

  const ProfileState({
    required this.loading,
    required this.profile,
    this.successMessage,
    this.errorMessage,
  });

  factory ProfileState.initial() =>
      const ProfileState(loading: false, profile: null);

  ProfileState copyWith({
    bool? loading,
    Map<String, dynamic>? profile,
    String? successMessage,
    String? errorMessage,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      profile: profile ?? this.profile,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [loading, profile, successMessage, errorMessage];
}
