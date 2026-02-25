import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// VerifyEmailPage
///
/// Email verification screen shown after user registration.
///
/// Responsibilities:
/// - Inform user about email verification requirement
/// - Allow opening email application
/// - Allow resending verification email
/// - Provide navigation back to login screen
class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

  /// _resendEmail()
  ///
  /// Resends the signup verification email to the current user.
  ///
  /// Flow:
  /// 1. Retrieve current authenticated user
  /// 2. Trigger Supabase resend with OtpType.signup
  Future<void> _resendEmail() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null && user.email != null) {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: user.email!,
      );
    }
  }

  /// _openEmailApp()
  ///
  /// Attempts to open the default email application.
  ///
  /// Flow:
  /// 1. Try launching mailto URI
  /// 2. If not available, open Gmail web in external browser
  Future<void> _openEmailApp() async {
    final uri = Uri(scheme: 'mailto');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://mail.google.com');
      await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// build()
  ///
  /// Builds the email verification UI.
  ///
  /// Responsibilities:
  /// - Display user email address
  /// - Provide verification instructions
  /// - Offer resend and navigation actions
  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

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
              const SizedBox(height: 60),

              /// Email icon container
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primaryGold,
                      Colors.amber,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 50,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Verify your email",
                style: AppTextStyles.title,
              ),

              const SizedBox(height: 10),

              const Text(
                "We sent an activation link to:",
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 12),

              Text(
                user?.email ?? "unknown email",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              /// Main instruction card
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
                    const Text(
                      "Open your email and click the link to activate your account.\n\n"
                      "Then return and log in again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// Open email app button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _openEmailApp,
                        icon: const Icon(
                          Icons.open_in_new,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "Open email app",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Resend verification email button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryGold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          await _resendEmail();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Email resent"),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primaryGold,
                        ),
                        label: const Text(
                          "Resend email",
                          style: TextStyle(
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// Back to login button
                    TextButton(
                      onPressed: () {
                        Supabase.instance.client.auth
                            .signOut();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginPage(),
                          ),
                          (_) => false,
                        );
                      },
                      child: const Text(
                        "Back to login",
                        style: TextStyle(
                          color: AppColors.textSecondary,
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