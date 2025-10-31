import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../core/connectivity/connectivity_service.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/auth/auth_state.dart';

class RequireOnlineAware extends StatelessWidget {
  final Widget child;
  final Widget? offlineWhenLoggedIn;
  final Widget? offlineWhenGuest;
  final bool blockNavigation;

  const RequireOnlineAware({
    super.key,
    required this.child,
    this.offlineWhenLoggedIn,
    this.offlineWhenGuest,
    this.blockNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        if (status == ConnectivityStatus.online) return child;

        final isAuthed = context.select<AuthBloc, bool>(
              (b) => b.state is AuthAuthenticated,
        );

        final fallback = isAuthed
            ? (offlineWhenLoggedIn ?? const _DefaultOfflineLoggedIn())
            : (offlineWhenGuest ?? const _DefaultOfflineGuest());

        return blockNavigation
            ? fallback
            : Stack(children: [child, Positioned.fill(child: fallback)]);
      },
    );
  }
}

class _DefaultOfflineLoggedIn extends StatelessWidget {
  const _DefaultOfflineLoggedIn();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Sin conexión. Modo limitado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estás autenticado. Puedes ver datos en caché; acciones online deshabilitadas.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Estás en modo offline. Algunas acciones están deshabilitadas.')),
                        );
                      },
                      child: const Text('Continuar en modo offline'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        context.read<ConnectivityCubit>().retry();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultOfflineGuest extends StatelessWidget {
  const _DefaultOfflineGuest();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Necesitas Internet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicia sesión cuando tengas conexión para continuar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    context.read<ConnectivityCubit>().retry();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
