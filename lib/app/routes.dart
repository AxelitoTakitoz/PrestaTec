// lib/app/routes.dart
import 'package:flutter/material.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/admin_home_screen.dart';
import '../features/home/presentation/user_home_screen.dart';
import '../features/admin/presentation/register_item_placeholder.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const adminHome = '/admin';
  static const userHome = '/user';
  static const registerItem = '/register';

  static Route<dynamic> onGenerate(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      case userHome:
        return MaterialPageRoute(builder: (_) => const UserHomeScreen());
      case registerItem:
        return MaterialPageRoute(builder: (_) => const RegisterItemPlaceholder());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
