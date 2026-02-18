import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({super.key});

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

Future<void> _openEmailApp() async {
  final uri = Uri(scheme: 'mailto');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    // fallback: abrir Gmail web
    final webUri = Uri.parse('https://mail.google.com');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Verifica tu correo")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 20),

            Text(
              "Te hemos enviado un correo de verificación a:",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            Text(
              user?.email ?? "correo desconocido",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Haz clic en el enlace del correo para activar tu cuenta.\n"
              "Una vez verificado, vuelve a iniciar sesión.",
              textAlign: TextAlign.center,
            ),
            

            const SizedBox(height: 40),
            
            ElevatedButton.icon(
              onPressed: _openEmailApp,
              icon: const Icon(Icons.open_in_new),
              label: const Text("Abrir app de correo"),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                await _resendEmail();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Correo reenviado")),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Reenviar correo"),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Supabase.instance.client.auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
              child: const Text("Volver al inicio de sesión"),
            ),
          ],
        ),
      ),
    );
  }
}
