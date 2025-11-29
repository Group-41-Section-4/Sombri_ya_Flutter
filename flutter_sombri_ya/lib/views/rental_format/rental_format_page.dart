import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../../presentation/blocs/rental_format/rental_format_bloc.dart';
import '../../presentation/blocs/rental_format/rental_format_event.dart';
import '../../presentation/blocs/rental_format/rental_format_state.dart';
import '../../../data/repositories/report_repository.dart';
import 'report_sent_page.dart';

class RentalFormatPage extends StatelessWidget {
  final String rentalId;

  const RentalFormatPage({
    super.key,
    required this.rentalId,
  });

  @override
  Widget build(BuildContext context) {
    final reportRepository = RepositoryProvider.of<ReportRepository>(context);


    return BlocProvider(
      create: (_) {
        return RentalFormatBloc(
          repository: reportRepository,
          rentalId: rentalId,
          connectivityCubit: context.read<ConnectivityCubit>(),
        );
      },
      child: _ReportProblemView(rentalId: rentalId),
    );
  }
}

class _ReportProblemView extends StatelessWidget {
  final String rentalId;

  const _ReportProblemView({required this.rentalId});

  TextStyle get _sectionLabelStyle => const TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: Color(0xFF4A4A4A),
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<RentalFormatBloc, RentalFormatState>(
      listenWhen: (previous, current) =>
      previous.submitSuccess != current.submitSuccess ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.submitSuccess) {
          final connectivityStatus =
              context.read<ConnectivityCubit>().state;
          final isOnline =
              connectivityStatus == ConnectivityStatus.online;



          if (!isOnline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Estás sin conexión. El reporte se guardó y se enviará automáticamente cuando tengas internet.',
                ),
              ),
            );
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ReportSentPage(),
            ),
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFF90E0EF),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Reportar Problema',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
                builder: (context, status) {
                  final isOffline =
                      status != ConnectivityStatus.online;


                  if (!isOffline) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    width: double.infinity,
                    color: Colors.amber[200],
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wifi_off, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estás sin conexión. Tu reporte se guardará y se enviará automáticamente cuando vuelva el internet.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calificación', style: _sectionLabelStyle),
                      const SizedBox(height: 8),
                      const _RatingRow(),
                      const SizedBox(height: 24),
                      Text('Describe el problema', style: _sectionLabelStyle),
                      const SizedBox(height: 8),
                      const _DescriptionField(),
                      const SizedBox(height: 24),
                      Text('Añadir fotos', style: _sectionLabelStyle),
                      const SizedBox(height: 8),
                      const _ImagePickerBox(),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _SubmitButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RentalFormatBloc, RentalFormatState>(
      buildWhen: (p, c) => p.someInt != c.someInt,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0E6EE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= state.someInt;

              return IconButton(
                splashRadius: 20,
                icon: Icon(
                  Icons.star,
                  size: 30,
                  color: isFilled
                      ? const Color(0xFFFFC94A)
                      : Colors.grey.shade300,
                ),
                onPressed: () {
                  final current = state.someInt;
                  final nextRating =
                  (current == starIndex) ? 0 : starIndex;


                  context
                      .read<RentalFormatBloc>()
                      .add(RatingChanged(nextRating));
                },
              );
            }),
          ),
        );
      },
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RentalFormatBloc, RentalFormatState>(
      buildWhen: (p, c) => p.description != c.description,
      builder: (context, state) {
        return TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Proporciona todos los detalles que puedas...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE0E6EE),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF90E0EF),
                width: 1.2,
              ),
            ),
          ),
          onChanged: (value) {
            context
                .read<RentalFormatBloc>()
                .add(DescriptionChanged(value));
          },
        );
      },
    );
  }
}

class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox();

  Future<void> _pickFrom(
      BuildContext context,
      ImageSource source,
      ) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (picked != null) {

      context
          .read<RentalFormatBloc>()
          .add(ImageChanged(File(picked.path)));
    } else {
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFrom(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFrom(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RentalFormatBloc, RentalFormatState>(
      buildWhen: (p, c) => p.imageFile != c.imageFile,
      builder: (context, state) {
        return InkWell(
          onTap: () {
            _showImageSourceSheet(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE0E6EE),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: state.imageFile == null
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Subir Fotos',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  state.imageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RentalFormatBloc, RentalFormatState>(
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: state.isSubmitting || !state.isValid
                ? null
                : () {

              context
                  .read<RentalFormatBloc>()
                  .add(const SubmitReportPressed());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001242),
              disabledBackgroundColor: const Color(0xFF90E0EF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: state.isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Enviar Reporte',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
