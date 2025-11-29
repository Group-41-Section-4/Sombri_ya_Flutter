import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class RentalFormatEvent extends Equatable {
  const RentalFormatEvent();

  @override
  List<Object?> get props => [];
}

class RatingChanged extends RentalFormatEvent {
  final int someInt;
  const RatingChanged(this.someInt);

  @override
  List<Object?> get props => [someInt];
}

class DescriptionChanged extends RentalFormatEvent {
  final String description;
  const DescriptionChanged(this.description);

  @override
  List<Object?> get props => [description];
}

class ImageChanged extends RentalFormatEvent {
  final File? imageFile;
  const ImageChanged(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class SubmitReportPressed extends RentalFormatEvent {
  const SubmitReportPressed();
}
