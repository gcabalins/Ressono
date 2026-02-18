import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'verify_email_page.dart';
import '../services/auth_errors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  bool loading = false;
  bool isFormValid = false;

  void _validateForm() {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final username = usernameCtrl.text.trim();

    final emailValid = RegExp(r"^[\w\.-]+@[\w\.-]+\.\w+$").hasMatch(email);

    setState(() {
      isFormValid = emailValid && pass.isNotEmpty && username.isNotEmpty;
    });
  }


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
      if (user == null) throw "No se pudo crear el usuario";

      // 2. Navegar a pantalla de verificación
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear cuenta")),
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
              onChanged: (_) => _validateForm(),

            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Contraseña"),
              obscureText: true,
              onChanged: (_) => _validateForm(),

            ),
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(labelText: "Nombre visible"),
              onChanged: (_) => _validateForm(),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: (loading || !isFormValid) ? null : _register,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Registrarse"),
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
