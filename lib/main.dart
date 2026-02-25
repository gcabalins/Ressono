import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_dependencies.dart';
import 'pages/auth_gate.dart';
import 'core/theme/app_theme.dart';

/// Application entry point.
///
/// Performs framework initialization,
/// configures external services,
/// sets up dependency injection,
/// and launches the root widget.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client.
  await Supabase.initialize(
    url: 'https://zqutxdesvnnajgccprak.supabase.co',
    anonKey: 'sb_publishable_Jbhl52PuvlBjEz566KE2rQ_0a3QKehg',
  );

  // Configure application dependencies.
  await setupDependencies();

  // Launch application.
  runApp(const MyApp());
}

/// Root application widget.
///
/// Configures:
/// - Application theme
/// - Navigation entry point
/// - Global app properties
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}