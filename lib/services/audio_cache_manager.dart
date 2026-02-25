import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Manages audio file caching.
///
/// This class:
/// - Configures a dedicated cache manager for audio files.
/// - Controls cache expiration and maximum stored items.
/// - Provides utilities for cache cleanup and size calculation.
class AudioCacheManager {
  static const _key = 'audioCache';

  static final AudioCacheManager _instance =
      AudioCacheManager._internal();

  /// Returns the singleton instance.
  factory AudioCacheManager() => _instance;

  AudioCacheManager._internal();

  /// CacheManager configured specifically for audio resources.
  ///
  /// - Files expire after 30 days.
  /// - Maximum of 100 cached files.
  static final CacheManager manager = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 100,
    ),
  );

  /// Clears all cached audio files.
  Future<void> clearCache() async {
    await manager.emptyCache();
  }

  /// Calculates total cache size in megabytes.
  ///
  /// Iterates through the audio cache directory
  /// and sums file sizes.
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

    return totalBytes / (1024 * 1024);
  }
}