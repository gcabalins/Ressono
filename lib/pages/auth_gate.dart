import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'login_page.dart';

/// Authentication gate widget.
///
/// Determines the initial screen of the application
/// based on the current authentication session.
///
/// If a valid session exists, the user is redirected
/// to the main application screen.
/// Otherwise, the login screen is displayed.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the current authentication session.
    final session = Supabase.instance.client.auth.currentSession;

    // Navigate to the main screen if the user is authenticated.
    if (session != null) {
      return const HomePage();
    }

    // Navigate to the login screen if no session exists.
    return const LoginPage();
  }
}