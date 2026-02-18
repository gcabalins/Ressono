import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import 'home_page.dart';
import '../services/auth_errors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);

    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.signInWithPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final user = supabase.auth.currentUser;

      // Actualizar perfil con metadata (si existe)
      final username = user?.userMetadata?['username'];
      if (username != null) {
        await supabase.from("profiles").update({
          "username": username,
        }).eq("id", user!.id);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      final msg = AuthErrorMapper.messageFromCode(e.toString());
      showErrorBanner(context, msg);
    }

    setState(() => loading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Iniciar sesión")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress, 
              autofillHints: const [AutofillHints.email], 
              autocorrect: false, 
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : _login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Entrar"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
              child: const Text("Crear cuenta"),
            ),
          ],
        ),
      ),
    );
  }
}
void showErrorBanner(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearMaterialBanners();

  messenger.showMaterialBanner(
    MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.error_outline, color: Colors.red),
      backgroundColor: Colors.red.withOpacity(0.05),
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => messenger.clearMaterialBanners(),
        ),
      ],
    ),
  );
}

