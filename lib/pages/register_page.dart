import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verify_email_page.dart';
import '../services/auth_errors.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// RegisterPage
///
/// User registration screen.
///
/// Responsibilities:
/// - Collect user credentials
/// - Validate form input
/// - Handle authentication flow
/// - Navigate to email verification screen after successful registration
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

/// _RegisterPageState
///
/// State management for RegisterPage.
///
/// Responsibilities:
/// - Manage form controllers
/// - Handle validation state
/// - Execute registration process
/// - Control loading and password visibility states
class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();

  bool loading = false;
  bool isFormValid = false;
  bool _obscurePassword = true;

  /// _validateForm()
  ///
  /// Validates user input fields and updates form validity state.
  ///
  /// Flow:
  /// 1. Trim input values
  /// 2. Validate email format using RegExp
  /// 3. Ensure password and username are not empty
  /// 4. Update isFormValid state
  void _validateForm() {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final username = usernameCtrl.text.trim();

    final emailValid = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email);

    setState(() {
      isFormValid = emailValid && pass.isNotEmpty && username.isNotEmpty;
    });
  }

  /// _register()
  ///
  /// Executes user registration using Supabase authentication.
  ///
  /// Flow:
  /// 1. Enable loading state
  /// 2. Call Supabase signUp with email, password, and username metadata
  /// 3. Validate returned user object
  /// 4. Navigate to VerifyEmailPage on success
  /// 5. Handle errors and display banner message
  /// 6. Disable loading state
  Future<void> _register() async {
    setState(() => loading = true);

    try {
      final supabase = Supabase.instance.client;

      final res = await supabase.auth.signUp(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        data: {
          "username": usernameCtrl.text.trim(),
        },
      );

      final user = res.user;
      if (user == null) throw "Registration failed";

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
      );
    } catch (e) {
      final msg = AuthErrorMapper.messageFromCode(e.toString());
      showErrorBanner(context, msg);
    }

    setState(() => loading = false);
  }

  /// build()
  ///
  /// Builds the registration screen UI.
  ///
  /// Responsibilities:
  /// - Render form inputs
  /// - Reflect validation state in button styling
  /// - Show loading indicator during registration
  /// - Provide password visibility toggle
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 40,
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// Header icon container
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryGold,
                      Colors.amber,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  size: 45,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Create your account",
                style: AppTextStyles.title,
              ),

              const SizedBox(height: 8),

              const Text(
                "Join Ressono",
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 40),

              /// Form container card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    /// Email input field
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _validateForm(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Email",
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Password input field with visibility toggle
                    TextField(
                      controller: passCtrl,
                      obscureText: _obscurePassword,
                      onChanged: (_) => _validateForm(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Password",
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Username input field
                    TextField(
                      controller: usernameCtrl,
                      onChanged: (_) => _validateForm(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Username",
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// Registration button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFormValid
                              ? AppColors.primaryGold
                              : Colors.grey.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: (loading || !isFormValid)
                            ? null
                            : _register,
                        child: loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                "Register",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
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
      ),
    );
  }
}

/// showErrorBanner()
///
/// Displays a MaterialBanner with an error message.
///
/// Flow:
/// 1. Clear existing banners
/// 2. Show error banner with dismiss action
void showErrorBanner(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearMaterialBanners();

  messenger.showMaterialBanner(
    MaterialBanner(
      backgroundColor: Colors.red.withOpacity(0.08),
      leading: const Icon(
        Icons.error_outline,
        color: Colors.redAccent,
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () => messenger.clearMaterialBanners(),
          child: const Text(
            "Close",
            style: TextStyle(
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    ),
  );
}