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
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;

  bool _isPublic = true; // 👈 NUEVO

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

    try {
      final uuid = Uuid();
      final trackId = uuid.v4();
      final fileName = "$trackId.mp3";

      final supabase = Supabase.instance.client;

      // 1️⃣ Obtener username del usuario
      final user = supabase.auth.currentUser;
      final profile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user!.id)
          .single();

      final username = profile['username'] as String;

      // 2️⃣ Subir archivo a Storage
      final storage = supabase.storage.from('audio');

      await storage.upload(
        fileName,
        _selectedFile!,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 3️⃣ Obtener URL pública
      final publicUrl = storage.getPublicUrl(fileName);

      // 4️⃣ Insertar en Supabase (tabla tracks)
      await supabase.from('tracks').insert({
        'id': trackId,
        'user_id': user.id,
        'title': _titleController.text,
        'artist': username, // 👈 artista se mantiene como estaba
        'audio_url': publicUrl,
        'duration_seconds': 0,
        'is_public': _isPublic, // 👈 NUEVO
      });

      // 5️⃣ Guardar en SQLite (para uso offline)
      final track = Track(
        id: trackId,
        title: _titleController.text,
        artist: username,
        audioUrl: publicUrl,
        durationSeconds: 0,
      );

      await trackRepository.insertTrack(track);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Canción subida')),
      );

      setState(() {
        _selectedFile = null;
        _fileName = null;
        _titleController.clear();
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

            const SizedBox(height: 16),

            // 👇 NUEVO: Switch para marcar si es pública
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hacer pública'),
                Switch(
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
              ],
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
