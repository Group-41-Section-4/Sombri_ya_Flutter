import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class WeatherCacheManager extends CacheManager {
  WeatherCacheManager._()
      : super(Config(
    'weather_json_cache',
    stalePeriod: const Duration(hours: 1),
    maxNrOfCacheObjects: 20,
    repo: JsonCacheInfoRepository(databaseName: 'weather_json_cache.db'),
    fileService: HttpFileService(),
  ));

  static final WeatherCacheManager instance = WeatherCacheManager._();
}
