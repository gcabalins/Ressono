import 'dart:io';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadTrackPage extends StatefulWidget {
  const UploadTrackPage({super.key});

  @override
  State<UploadTrackPage> createState() => _UploadTrackPageState();
}

class _UploadTrackPageState extends State<UploadTrackPage> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  PickedAudio? _selectedAudio;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final audio  = await pickAudioFile();
    if (audio  != null) {
      setState(() {
        _selectedAudio = audio ;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedAudio == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título y archivo son obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int durationSeconds = 0;

      // ⏱️ Duración SOLO en móvil
      if (!kIsWeb && _selectedAudio!.file != null) {
        durationSeconds =
            await getAudioDurationSeconds(_selectedAudio!.file!);
      }

      // ⬆️ Subir archivo (WEB o móvil)
      final url = await uploadAudioFile(_selectedAudio!);

      // 💾 Insertar en DB
      await insertTrack(
        title: _titleController.text,
        artist:
            _artistController.text.isEmpty ? null : _artistController.text,
        audioUrl: url,
        durationSeconds: durationSeconds,
      );
      print(  '✅ Canción insertada en DB: $url, durationSeconds: $durationSeconds');
      if (kIsWeb && durationSeconds == 0) {
        final realDuration = await getDurationFromUrl(url);
        print(  'ℹ️ Duración real obtenida en WEB: $realDuration segundos');
        if (realDuration > 0) {
          await updateTrackDuration(
            audioUrl: url,
            durationSeconds: realDuration,
          );
        }
      }


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Canción subida')),
      );

      setState(() {
        _selectedAudio = null;
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
                    _selectedAudio != null
                        ? _selectedAudio!.name
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
