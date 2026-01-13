import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MetadataCache {
  static final MetadataCache _instance = MetadataCache._internal();
  factory MetadataCache() => _instance;
  MetadataCache._internal();

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/metadata_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('📁 Metadata cache creada');
    }
    return dir;
  }

  Future<File> _file(String name) async {
    final dir = await _dir();
    return File('${dir.path}/$name.json');
  }

  Future<void> save(String key, List<Map<String, dynamic>> data) async {
    final file = await _file(key);
    await file.writeAsString(jsonEncode(data));
    print('💾 Metadata guardada → $key (${data.length})');
  }

  Future<List<Map<String, dynamic>>?> load(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      print('📦 Metadata cargada → $key (${list.length})');
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      print('❌ Error leyendo metadata $key → $e');
      return null;
    }
  }
}
