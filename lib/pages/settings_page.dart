import 'package:flutter/material.dart';
import '../services/audio_cache.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final cache = AudioCacheManager();
  double? cacheSize;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await cache.getCacheSizeMB();
    setState(() => cacheSize = size);
  }

  Future<void> _clearCache() async {
    await cache.clearCache();
    await _loadCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caché de audio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cacheSize == null
                  ? 'Calculando...'
                  : 'Espacio usado: ${cacheSize!.toStringAsFixed(2)} MB',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              'Límite máximo: ${cache.maxCacheSizeMB} MB',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _clearCache,
              icon: const Icon(Icons.delete),
              label: const Text('Limpiar caché'),
            ),
          ],
        ),
      ),
    );
  }
}
