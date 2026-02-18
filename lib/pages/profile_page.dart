import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/audio_service.dart';
import 'settings_page.dart';
import '../services/audio_cache_manager.dart';
import 'login_page.dart';
import 'package:image_picker/image_picker.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  double? _cacheSizeMB;
  String? username;
  String? avatarUrl;


  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadProfile();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final user = supabase.auth.currentUser!;
    final bytes = await file.readAsBytes();
    final fileExt = file.path.split('.').last;
    final fileName = "${user.id}.$fileExt";

    // Subir a Storage
    await supabase.storage
        .from('avatars')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(upsert: true),
        );

    // Obtener URL pública
    final url = supabase.storage
        .from('avatars')
        .getPublicUrl(fileName);

    // Guardar en profiles
    await supabase.from('profiles').update({
      'avatar_url': url,
    }).eq('id', user.id);

    setState(() {
      avatarUrl = url;
    });
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from("profiles")
        .select("username")
        .eq("id", user.id)
        .maybeSingle();

    setState(() {
      username = data?["username"];
      avatarUrl = data?["avatar_url"];
    });
  }


  Future<void> _loadCacheSize() async {
  final size = await AudioCacheManager().getCacheSizeMB();
    setState(() {
      _cacheSizeMB = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Center(child: Text('No autenticado'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(username ?? "Cargando..."),
            subtitle: Text(user.email ?? "Sin email"),
            trailing: TextButton(
              child: const Text("Cambiar"),
              onPressed: _pickAndUploadAvatar,
            ),
          ),

          const Divider(),

          // 📊 DATOS
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Caché local'),
            subtitle: Text(
              _cacheSizeMB == null
                  ? 'Calculando...'
                  : '${_cacheSizeMB!.toStringAsFixed(2)} MB',
            ),
          ),

          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ajustes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),


          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await supabase.auth.signOut();
              AudioService().stopAndClear();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sesión cerrada')),
              );
              // Redirigir al login 
              Navigator.pushAndRemoveUntil( 
                context, 
                MaterialPageRoute(builder: (_) => const LoginPage()), 
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}