import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zqutxdesvnnajgccprak.supabase.co',
    anonKey: 'sb_publishable_Jbhl52PuvlBjEz566KE2rQ_0a3QKehg',
  );
  final supabase = Supabase.instance.client;

  await supabase.auth.signInWithPassword(
    email: 'gcabalins@gmail.com',      // el mismo que pusiste al crear el usuario
    password: '12345678',        // la contraseña que tú escribiste allí
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
