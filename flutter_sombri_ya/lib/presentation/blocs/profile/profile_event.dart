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

class RefreshProfile extends ProfileEvent {
  final String userId;
  const RefreshProfile(this.userId);
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

// class LoadTotalDistance extends ProfileEvent {
//   final String userId;
//   const LoadTotalDistance(this.userId);
//   @override
//   List<Object?> get props => [userId];
// }

class ClearProfileMessages extends ProfileEvent {
  const ClearProfileMessages();
}

class UpdateProfilePhoto extends ProfileEvent {
  final String imagePath;
  const UpdateProfilePhoto(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class DeleteAccount extends ProfileEvent {
  final bool hard;
  const DeleteAccount({this.hard = false});

  @override
  List<Object?> get props => [hard];
}
