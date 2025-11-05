import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void tuneImageCache({int maxEntries = 300, int maxBytesMB = 120}) {
  final cache = PaintingBinding.instance.imageCache;
  cache.maximumSize = maxEntries;
  cache.maximumSizeBytes = maxBytesMB << 20;
}

String imageCacheStats() {
  final c = PaintingBinding.instance.imageCache;
  final bytesMB = (c.currentSizeBytes / (1024 * 1024)).toStringAsFixed(1);
  final maxMB = (c.maximumSizeBytes / (1024 * 1024)).toStringAsFixed(0);
  return '[ImageCache] size=${c.currentSize} live=${c.liveImageCount} bytes=${bytesMB}MB max=${c.maximumSize}/${maxMB}MB';
}

const List<ImageProvider> _defaultWarmupAssets = <ImageProvider>[
  AssetImage('assets/images/logo_no_bg.png'),
  AssetImage('assets/images/pin.png'),
  AssetImage('assets/images/pin_no_umbrella.png'),
  AssetImage('assets/images/umbrella.png'),
  AssetImage('assets/images/umbrella_available.png'),
  AssetImage('assets/images/profile.png'),
  AssetImage('assets/images/notification.png'),
];

Future<void> warmUpAppImages(
  BuildContext context, {
  List<ImageProvider>? assets,
  bool log = false, 
}) async {
  if (kDebugMode && log) debugPrint('ANTES  ${imageCacheStats()}');

  final list = assets ?? _defaultWarmupAssets;
  for (final provider in list) {
    await precacheImage(provider, context);
    if (kDebugMode && log) {
      debugPrint('[precache] $provider');
    }
  }

  if (kDebugMode && log) {
    debugPrint('DESPUÉS ${imageCacheStats()}');
  }
}

void scheduleWarmUp(
  BuildContext context, {
  List<ImageProvider>? assets,
  bool log = false, 
}) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    warmUpAppImages(context, assets: assets, log: log);
  });
}

// Tests
@visibleForTesting
void clearImageCacheForTest({bool log = false}) {
  final cache = PaintingBinding.instance.imageCache;
  cache.clear();
  cache.clearLiveImages();
  if (kDebugMode && log) debugPrint('LIMPIADO ${imageCacheStats()}');
}
