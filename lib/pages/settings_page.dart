import 'package:flutter/material.dart';
import '../services/audio_cache_manager.dart';

/// SettingsPage
///
/// Application settings screen.
///
/// Responsibilities:
/// - Display current audio cache usage
/// - Allow user to clear cached audio files
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// _SettingsPageState
///
/// State management for SettingsPage.
///
/// Responsibilities:
/// - Retrieve cache size on initialization
/// - Handle cache clearing action
/// - Update UI according to cache state
class _SettingsPageState extends State<SettingsPage> {
  final cache = AudioCacheManager();

  double? cacheSize;

  /// initState()
  ///
  /// Initializes the state and triggers cache size loading.
  ///
  /// Flow:
  /// 1. Call superclass initState
  /// 2. Load current cache size
  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  /// _loadCacheSize()
  ///
  /// Retrieves the current audio cache size in megabytes.
  ///
  /// Flow:
  /// 1. Request cache size from AudioCacheManager
  /// 2. Update cacheSize state
  Future<void> _loadCacheSize() async {
    final size = await cache.getCacheSizeMB();
    setState(() {
      cacheSize = size;
    });
  }

  /// _clearCache()
  ///
  /// Clears all cached audio files and refreshes cache size.
  ///
  /// Flow:
  /// 1. Execute cache clearing
  /// 2. Reload updated cache size
  Future<void> _clearCache() async {
    await cache.clearCache();
    await _loadCacheSize();
  }

  /// build()
  ///
  /// Builds the settings screen UI.
  ///
  /// Responsibilities:
  /// - Display cache usage information
  /// - Provide action button to clear cache
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Cache')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cacheSize == null
                  ? 'Calculating...'
                  : 'Use space: ${cacheSize!.toStringAsFixed(2)} MB',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),

            /// Button to clear audio cache
            ElevatedButton.icon(
              onPressed: _clearCache,
              icon: const Icon(Icons.delete),
              label: const Text('Clear Cache'),
            ),
          ],
        ),
      ),
    );
  }
}