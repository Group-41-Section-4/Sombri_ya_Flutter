import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String userId;
  const LoadProfile(this.userId);
  @override
  List<Object?> get props => [userId];
}

class UpdateProfileField extends ProfileEvent {
  final String userId;
  final String fieldKey;  
  final String newValue;

  const UpdateProfileField({
    required this.userId,
    required this.fieldKey,
    required this.newValue,
  });

  @override
  List<Object?> get props => [userId, fieldKey, newValue];
}

class ChangePassword extends ProfileEvent {
  final String userId;
  final String currentPassword;
  final String newPassword;         

  const ChangePassword({
    required this.userId,
    required this.currentPassword,
    required this.newPassword,      
  });

  @override
  List<Object?> get props => [userId, currentPassword, newPassword];
}

class RefreshProfile extends ProfileEvent {
  final String userId;
  const RefreshProfile(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ClearProfileMessages extends ProfileEvent {
  const ClearProfileMessages();
}
