import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app/theme.dart';
import 'app/routes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PrestaTecApp());
}

class PrestaTecApp extends StatelessWidget {
  const PrestaTecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrestaTec',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRoutes.onGenerate,
      initialRoute: AppRoutes.splash,
    );
  }
}