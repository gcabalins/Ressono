import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/audio_service.dart';
import 'settings_page.dart';
import '../services/audio_cache_manager.dart';
import 'login_page.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// ProfilePage
///
/// Displays user profile information and account options.
///
/// Responsibilities:
/// - Show user avatar and username
/// - Upload and update profile picture
/// - Display local cache usage
/// - Navigate to settings
/// - Handle user logout
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// _ProfilePageState
///
/// Manages profile loading, avatar upload,
/// cache size calculation, and logout logic.
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

  /// Opens image picker and uploads selected avatar to Supabase Storage.
  ///
  /// Updates the user profile with the new avatar URL.
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final user = supabase.auth.currentUser!;
    final bytes = await file.readAsBytes();
    final fileExt = file.path.split('.').last;
    final fileName = "${user.id}.$fileExt";
    await supabase.storage
        .from('avatars')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(upsert: true, metadata: {'owner': user.id}),
        );
    final url = supabase.storage.from('avatars').getPublicUrl(fileName);
    await supabase
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', user.id);

    setState(() {
      avatarUrl = url;
    });
  }

  /// Loads username and avatar URL from the profiles table.
  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from("profiles")
        .select("username, avatar_url")
        .eq("id", user.id)
        .maybeSingle();

    setState(() {
      username = data?["username"];
      avatarUrl = data?["avatar_url"];
    });
  }
  /// Calculates and loads current local audio cache size.
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
      return const Center(child: Text('Not authenticated'));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// Profile Header Section
          ///
          /// Displays avatar, username, email,
          /// and avatar change hint.
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryGold, Colors.amber],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: AppColors.surface,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl!)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 45,
                                color: AppColors.textSecondary,
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    username ?? "User",
                    style: AppTextStyles.title.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(user.email ?? "", style: AppTextStyles.subtitle),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the image to change avatar",
                    style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          /// Profile Options Section
          ///
          /// Contains cache info, settings navigation,
          /// and logout action.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCard(
                    icon: Icons.storage,
                    title: "Local cache",
                    subtitle: _cacheSizeMB == null
                        ? "Calculating..."
                        : "${_cacheSizeMB!.toStringAsFixed(2)} MB",
                  ),

                  const SizedBox(height: 16),
                  _buildCard(
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  _buildCard(
                    icon: Icons.logout,
                    title: "Log out",
                    isDanger: true,
                    onTap: () async {
                      await supabase.auth.signOut();
                      AudioService().stopAndClear();

                      if (!mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (_) => false,
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  /// Reusable profile option card widget.
  ///
  /// Supports:
  /// - Optional subtitle
  /// - Navigation arrow
  /// - Danger styling (e.g. logout)
  Widget _buildCard({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isDanger
                    ? Colors.redAccent.withOpacity(0.15)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDanger ? Colors.redAccent : AppColors.primaryGold,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title),
                  if (subtitle != null)
                    Text(subtitle, style: AppTextStyles.subtitle),
                ],
              ),
            ),

            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
