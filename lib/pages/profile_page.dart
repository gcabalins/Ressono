import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/audio_cache.dart';
import '../services/audio_controller.dart';
import 'settings_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  double? _cacheSizeMB;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
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
          // 👤 USUARIO
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(user.email ?? 'Sin email'),
            subtitle: Text(
              'ID: ${user.id.substring(0, 6)}...',
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

          // 🔥 ACCIONES
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Limpiar caché'),
            onTap: () async {
              await AudioCacheManager().clearCache();
              await _loadCacheSize();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caché limpiada')),
              );
            },
          ),
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
              AudioController().stopAndClear();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sesión cerrada')),
              );
            },
          ),
        ],
      ),
    );
  }
}
