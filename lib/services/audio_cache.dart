import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const int MAX_CACHE_SIZE = 1024 * 1024 * 1024; // 1 GB

class AudioCacheManager {
  static const _cacheFolder = 'audio_cache';
  static final AudioCacheManager _instance = AudioCacheManager._internal();
  factory AudioCacheManager() => _instance;
  AudioCacheManager._internal();

  /// Carpeta raíz de cache
  Future<Directory> _cacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/audio_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
      print('📁 Cache creada en ${cacheDir.path}');
    }
    return cacheDir;
  }

  /// Obtiene audio (cache o descarga)
  Future<File?> getCachedAudio({
    required String trackId,
    required String audioUrl,
  }) async {
    final cacheDir = await _cacheDir();
    final file = File('${cacheDir.path}/$trackId.mp3');

    if (await file.exists()) {
      print('✅ CACHE HIT → $trackId');
      return file;
    }

    print('⬇️ CACHE MISS → descargando $trackId');
    return await _downloadAndCache(file, audioUrl);
  }

  /// Descarga + guarda
  Future<File?> _downloadAndCache(File file, String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      final bytes = response.bodyBytes.length;
      print('📥 Descargados ${(bytes / 1024 / 1024).toStringAsFixed(2)} MB');

      await file.writeAsBytes(response.bodyBytes);

      await _enforceCacheLimit();

      return file;
    } catch (e) {
      print('❌ Error descargando audio: $e');
      return null;
    }
  }

  /// Tamaño total de cache
  Future<int> _totalCacheSize() async {
    final dir = await _cacheDir();
    int total = 0;

    for (final f in dir.listSync()) {
      if (f is File) {
        total += await f.length();
      }
    }

    print('📦 Cache total: ${(total / 1024 / 1024).toStringAsFixed(2)} MB');
    return total;
  }

  /// LRU simple (borra más antiguos)
  Future<void> _enforceCacheLimit() async {
    int total = await _totalCacheSize();
    if (total <= MAX_CACHE_SIZE) return;

    print('🧹 Cache excede 1GB, limpiando...');

    final dir = await _cacheDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .toList()
      ..sort((a, b) =>
          a.statSync().modified.compareTo(b.statSync().modified));

    for (final f in files) {
      final size = await f.length();
      await f.delete();
      total -= size;

      print('🗑️ Eliminado ${f.path.split('/').last}');

      if (total <= MAX_CACHE_SIZE) break;
    }
  }

  /// Limpieza manual
  Future<void> clearCache() async {
    final dir = await _cacheDir();
    for (final f in dir.listSync()) {
      if (f is File) await f.delete();
    }
    print('🔥 Cache limpiada manualmente');
  }
  Future<bool> isTrackCached(String trackId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_cacheFolder/$trackId.mp3');
    return file.exists();
  }
}
