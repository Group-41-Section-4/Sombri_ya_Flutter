import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../core/connectivity/connectivity_service.dart';

class RequireOnline extends StatelessWidget {
  final Widget child;
  final Widget? offline;
  final bool blockNavigation;
  const RequireOnline({
    super.key,
    required this.child,
    this.offline,
    this.blockNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, status) {
        if (status == ConnectivityStatus.online) return child;
        final fallback = offline ?? const _DefaultOfflineView();
        return blockNavigation ? fallback : Stack(children: [child, Positioned.fill(child: fallback)]);
      },
    );
  }
}

class _DefaultOfflineView extends StatelessWidget {
  const _DefaultOfflineView();
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
                const Text('Sin conexión a Internet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Verifica datos o Wi-Fi. Intentaremos reconectar automáticamente.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: () {}, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
