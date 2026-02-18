import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioCacheManager {
  static const _key = 'audioCache';

  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;

  AudioCacheManager._internal();

  static final CacheManager manager = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30), // cuánto tiempo se conserva
      maxNrOfCacheObjects: 100, 

    ),
  );
  Future<void> clearCache() async {
    await manager.emptyCache();
  }

  Future<double> getCacheSizeMB() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory("${tempDir.path}/audioCache");

    if (!cacheDir.existsSync()) {
      return 0.0;
    }

    int totalBytes = 0;

    for (final entity in cacheDir.listSync(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }

    // Convertir bytes → MB
    return totalBytes / (1024 * 1024);
  }

}
