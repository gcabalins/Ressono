import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/track.dart';
import 'package:uuid/uuid.dart';
import '../app_dependencies.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// UploadTrackPage
///
/// Screen for uploading a new audio track.
///
/// Responsibilities:
/// - Collect track metadata
/// - Pick local audio file
/// - Upload file to Supabase Storage
/// - Persist track in remote database and local storage
class UploadTrackPage extends StatefulWidget {
  const UploadTrackPage({super.key});

  @override
  State<UploadTrackPage> createState() => _UploadTrackPageState();
}

/// _UploadTrackPageState
///
/// State management for UploadTrackPage.
///
/// Responsibilities:
/// - Manage form inputs and file selection
/// - Handle upload workflow
/// - Control loading and visibility state
class _UploadTrackPageState extends State<UploadTrackPage> {
  final _titleController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;

  bool _isPublic = true;

  /// _pickFile()
  ///
  /// Opens file picker to select an audio file.
  ///
  /// Flow:
  /// 1. Open FilePicker with audio filter
  /// 2. Validate selected file path
  /// 3. Store file reference and name in state
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

  /// _saveTrack()
  ///
  /// Uploads the selected track and saves metadata.
  ///
  /// Flow:
  /// 1. Validate required fields
  /// 2. Generate unique track ID
  /// 3. Retrieve current user profile
  /// 4. Upload audio file to Supabase Storage
  /// 5. Insert track metadata into Supabase table
  /// 6. Store track locally for offline access
  /// 7. Reset form state
  Future<void> _saveTrack() async {
    if (_selectedFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and file are required'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uuid = Uuid();
      final trackId = uuid.v4();
      final fileName = "$trackId.mp3";

      final supabase = Supabase.instance.client;

      final user = supabase.auth.currentUser;

      final profile = await supabase
          .from('profiles')
          .select('username')
          .eq('id', user!.id)
          .single();

      final username = profile['username'] as String;

      final storage = supabase.storage.from('audio');

      await storage.upload(
        fileName,
        _selectedFile!,
        fileOptions:
            const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = storage.getPublicUrl(fileName);

      await supabase.from('tracks').insert({
        'id': trackId,
        'user_id': user.id,
        'title': _titleController.text,
        'artist': username,
        'audio_url': publicUrl,
        'duration_seconds': 0,
        'is_public': _isPublic,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      final track = Track(
        id: trackId,
        userId: user.id,
        title: _titleController.text,
        artist: username,
        audioUrl: publicUrl,
        durationSeconds: 0,
        createdAt: DateTime.now(),
      );

      await trackRepository.insertTrack(track);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song uploaded successfully'),
        ),
      );

      setState(() {
        _selectedFile = null;
        _fileName = null;
        _titleController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// build()
  ///
  /// Builds the upload track UI.
  ///
  /// Responsibilities:
  /// - Render metadata input fields
  /// - Provide public/private switch
  /// - Allow audio file selection
  /// - Trigger upload process
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Main upload card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Track information",
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 20),

                  /// Title input field
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// Public visibility switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Make public',
                          style: AppTextStyles.subtitle,
                        ),
                        Switch(
                          activeColor: AppColors.primaryGold,
                          value: _isPublic,
                          onChanged: (v) =>
                              setState(() => _isPublic = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// Audio file selector
                  GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color: _selectedFile == null
                              ? AppColors.textSecondary
                              : AppColors.primaryGold,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            color: _selectedFile == null
                                ? AppColors.textSecondary
                                : AppColors.primaryGold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _fileName ??
                                  "Select audio file",
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Upload button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryGold,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                      onPressed:
                          _isLoading ? null : _saveTrack,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              "Save track",
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}