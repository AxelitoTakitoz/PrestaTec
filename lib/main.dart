// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app/routes.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 Correos en español
  FirebaseAuth.instance.setLanguageCode('es');

  runApp(const PrestaTecApp());
}

class PrestaTecApp extends StatelessWidget {
  const PrestaTecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrestaTec',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.roleGate,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
