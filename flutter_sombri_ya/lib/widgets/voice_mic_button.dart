import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../presentation/blocs/voice/voice_bloc.dart';
import '../../presentation/blocs/voice/voice_event.dart';
import '../../presentation/blocs/voice/voice_state.dart';
import '../../domain/voice/voice_intent.dart';

import '../../views/rent/rent_page.dart';
import '../../views/return/return_page.dart';

import '../../data/repositories/rental_repository.dart';
import '../../presentation/blocs/return/return_bloc.dart';
import '../../presentation/blocs/return/return_event.dart';
import '../../data/models/gps_coord.dart';
import '../../services/location_service.dart';

import '../../data/repositories/profile_repository.dart';


class VoiceMicButton extends StatelessWidget {
  const VoiceMicButton({super.key});

  static DateTime? _lastNavAt;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoiceBloc, VoiceState>(
      listenWhen: (prev, curr) =>
          prev.intent != curr.intent && curr.intent != VoiceIntent.none,
      listener: (context, state) async {
        final now = DateTime.now();
        if (_lastNavAt != null &&
            now.difference(_lastNavAt!) < const Duration(seconds: 2)) {
          return;
        }
        _lastNavAt = now;

        context.read<VoiceBloc>().add(const VoiceStopRequested());

        switch (state.intent) {
          case VoiceIntent.rentDefault: 
          case VoiceIntent.rentQR:     
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RentPage()),
            );
            break;

          case VoiceIntent.rentNFC:     
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RentPage()),
            );
            break;

          case VoiceIntent.returnUmbrella: {
            final loc = await LocationService.getPosition();
            final userGps = (loc != null)
                ? GpsCoord(latitude: loc.latitude, longitude: loc.longitude)
                : GpsCoord(latitude: 0, longitude: 0);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider(
                      create: (_) => RentalRepository(
                        storage: const FlutterSecureStorage(),
                      ),
                    ),
                    RepositoryProvider(
                      create: (_) => ProfileRepository(),
                    ),
                  ],
                  child: BlocProvider(
                    create: (ctx) => ReturnBloc(
                      repo: RepositoryProvider.of<RentalRepository>(ctx),
                      profileRepo: RepositoryProvider.of<ProfileRepository>(ctx),
                    )..add(const ReturnInit()),
                    child: ReturnPage(userPosition: userGps),
                  ),
                ),
              ),
            );
            break;
          }

          case VoiceIntent.none:
            break;
        }

        context.read<VoiceBloc>().add(const VoiceClearIntent());
      },
      builder: (context, state) {
        return FloatingActionButton.extended(
          onPressed: () async {
            final status = await Permission.microphone.request();

            if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
              if (status.isPermanentlyDenied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, habilita el permiso de micrófono desde la configuración del dispositivo.',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Permiso de micrófono: $status')),
                );
              }
              return;
            }

            final bloc = context.read<VoiceBloc>();
            if (state.isListening) {
              bloc.add(const VoiceStopRequested());
            } else {
              bloc.add(const VoiceStartRequested());
            }
          },
          icon: Icon(state.isListening ? Icons.mic : Icons.mic_none),
          label: Text(state.isListening ? 'Escuchando…' : 'Hablar'),
        );
      },
    );
  }
}
