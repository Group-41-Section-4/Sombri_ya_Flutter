import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_links/app_links.dart';
import 'main.dart';
import 'presentation/blocs/weather/weather_cubit.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  bool _navigating = false;
  String? _lastHandled;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final wx = context.read<WeatherCubit>();
      await wx.emitFromCachedForecastOrState();
      unawaited(wx.start(
        every: const Duration(minutes: 15),
        ttl: const Duration(minutes: 10),
      ));
    });

    _setupLinks();
  }

  Future<void> _setupLinks() async {
    _appLinks = AppLinks();

    try {
      Uri? initialUri = await _appLinks.getInitialLink();
      initialUri ??= await _appLinks.getLatestLink();

      if (initialUri != null) {
        _handleUri(initialUri, source: 'initial/latest');
      } else {
        debugPrint('[DeepLink] (initial/latest) = null');
      }
    } catch (e) {
      debugPrint('[DeepLink] initial error: $e');
    }

    _linkSub = _appLinks.uriLinkStream.listen(
          (uri) => _handleUri(uri, source: 'stream'),
      onError: (e) => debugPrint('[DeepLink] stream error: $e'),
    );
  }

  void _handleUri(Uri uri, {String source = ''}) async {
    final linkStr = uri.toString();
    if (_lastHandled == linkStr) {
      debugPrint('[DeepLink] ($source) duplicated, skipping');
      return;
    }


    final isCustom = uri.scheme == 'sombri-ya' && uri.host == 'reset-password';

    final isHttps = uri.scheme == 'https' &&
        uri.host == 'sombri-ya.app' &&
        (uri.path == '/reset' || uri.path.startsWith('/reset/'));

    if (!(isCustom || isHttps)) {
      debugPrint('[DeepLink] not matching reset route');
      return;
    }

    final user  = uri.queryParameters['user'];
    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      debugPrint('[DeepLink] missing token');
      return;
    }

    if (_navigating) return;
    _navigating = true;
    _lastHandled = linkStr;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final nav = navigatorKey.currentState;
      if (nav == null) {
        debugPrint('[DeepLink] navigatorKey state is null');
        _navigating = false;
        return;
      }

      try {
        await nav.pushNamed(
          '/reset',
          arguments: {
            'userId': user!,
            'token': token,
          },
        );
      } finally {
        _navigating = false;
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
