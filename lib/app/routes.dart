// lib/app/routes.dart
import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/pantalla_de_registro.dart';
import '../features/auth/presentation/role_gate_screen.dart';

import '../features/home/presentation/admin_home_screen.dart';
import '../features/home/presentation/user_home_screen.dart';

import '../features/admin/presentation/register_item_placeholder.dart';

class AppRoutes {
  static const roleGate = '/';
  static const login = '/login';
  static const register = '/register';

  static const adminHome = '/adminHome';
  static const userHome = '/userHome';

  static const registerItem = '/registerItem';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => RegistroScreen());
      case adminHome:
        return MaterialPageRoute(builder: (_) => const AdminHomeScreen());
      case userHome:
        return MaterialPageRoute(builder: (_) => const UserHomeScreen());
      case registerItem:
        return MaterialPageRoute(builder: (_) => const RegisterItemPlaceholder());
      case roleGate:
      default:
        return MaterialPageRoute(builder: (_) => const RoleGateScreen());
    }
  }
}
