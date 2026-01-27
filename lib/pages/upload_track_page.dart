import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/track.dart';
import 'package:uuid/uuid.dart'; 
import '../app_dependencies.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class UploadTrackPage extends StatefulWidget {
  const UploadTrackPage({super.key});

  @override
  State<UploadTrackPage> createState() => _UploadTrackPageState();
}

class _UploadTrackPageState extends State<UploadTrackPage> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;


  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _saveTrack() async {
    if (_selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título y archivo son obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final uuid = Uuid();
    try { 
      final trackId = uuid.v4(); final fileName = "$trackId.mp3"; 
      // 1️⃣ Subir archivo a Supabase Storage 
      final storage = Supabase.instance.client.storage.from('audio');

      await storage.upload( 
        fileName, 
        _selectedFile!, 
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false), 
      ); 
      // 2️⃣ Obtener URL pública 
      final publicUrl = Supabase.instance.client.storage
      .from('audio')
      .getPublicUrl(fileName);
      print ("Hoal$publicUrl");

      // 3️⃣ Crear track con URL remota 
      final track = Track( 
        id: trackId, 
        title: _titleController.text, 
        artist: _artistController.text.isEmpty 
          ? 'Artista desconocido' 
          : _artistController.text, 
          audioUrl: publicUrl, 
          durationSeconds: 0, 
        );
      // 4️⃣ Guardar en SQLite + sincronizar
      await trackRepository.insertTrack(track);


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Canción añadida')),
      );

      setState(() {
        _selectedFile = null;
        _fileName = null;
        _titleController.clear();
        _artistController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir canción')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _artistController,
              decoration:
                  const InputDecoration(labelText: 'Artista (opcional)'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickFile,
                  child: const Text('Elegir audio'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName ?? 'Ningún archivo seleccionado',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveTrack,
              child: Text(_isLoading ? 'Guardando...' : 'Guardar canción'),
            ),
          ],
        ),
      ),
    );
  }
}
