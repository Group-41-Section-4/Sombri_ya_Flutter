import 'dart:io';
import 'package:equatable/equatable.dart';

class RentalFormatState extends Equatable {
  final int someInt;
  final String? description;
  final File? imageFile;
  final bool isSubmitting;
  final bool submitSuccess;
  final String? errorMessage;

  const RentalFormatState({
    this.someInt = 0,
    this.description,
    this.imageFile,
    this.isSubmitting = false,
    this.submitSuccess = false,
    this.errorMessage,
  });

  bool get isValid => someInt > 0;

  String? get descriptionOrNull {
    final trimmed = description?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  RentalFormatState copyWith({
    int? rating,
    String? description,
    File? imageFile,
    bool? isSubmitting,
    bool? submitSuccess,
    String? errorMessage,
  }) {
    return RentalFormatState(
      someInt: rating ?? this.someInt,
      description: description ?? this.description,
      imageFile: imageFile ?? this.imageFile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitSuccess: submitSuccess ?? this.submitSuccess,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [someInt, description, imageFile, isSubmitting, submitSuccess, errorMessage];
}
