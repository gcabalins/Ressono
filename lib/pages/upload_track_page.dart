import 'dart:io';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class UploadTrackPage extends StatefulWidget {
  const UploadTrackPage({super.key});

  @override
  State<UploadTrackPage> createState() => _UploadTrackPageState();
}

class _UploadTrackPageState extends State<UploadTrackPage> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  File? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final file = await pickAudioFile();
    if (file != null) {
      setState(() {
        _selectedFile = file;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título y archivo son obligatorios')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Calcular duración
      final durationSeconds = await getAudioDurationSeconds(_selectedFile!);
      if (durationSeconds == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer la duración del audio')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Subir archivo
      final url = await uploadAudioFile(_selectedFile!);

      // 3. Insertar fila en tracks con duración
      await insertTrack(
        title: _titleController.text,
        artist: _artistController.text.isEmpty ? null : _artistController.text,
        audioUrl: url,
        durationSeconds: durationSeconds, // AQUÍ
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canción subida')),
      );

      setState(() {
        _selectedFile = null;
        _titleController.clear();
        _artistController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              decoration: const InputDecoration(labelText: 'Artista (opcional)'),
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
                    _selectedFile != null
                        ? _selectedFile!.path.split('/').last
                        : 'Ningún archivo seleccionado',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _upload,
              child: Text(_isLoading ? 'Subiendo...' : 'Subir canción'),
            ),
          ],
        ),
      ),
    );
  }
}
