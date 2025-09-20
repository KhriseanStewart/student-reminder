import 'package:flutter/material.dart';
import 'package:students_reminder/src/features/auth/login_page.dart';
import 'package:students_reminder/src/features/auth/register_page.dart';
import 'package:students_reminder/src/features/profile/student_profile_page.dart';
import 'package:students_reminder/src/features/splash/splash_gate.dart';
import 'package:students_reminder/src/features/admin/admin.dart';

class AppRoutes {
  // 🔑 Centralized route names
  static const root = '/'; // Always SplashGate
  static const login = '/login';
  static const register = '/register';
  static const admin = '/admin';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final url = Uri.parse(settings.name ?? '');

    // 🔹 Handle /student/:uid route
    if (url.pathSegments.isNotEmpty && url.pathSegments[0] == 'student') {
      final uid = url.pathSegments.length > 1 ? url.pathSegments[1] : '';
      return MaterialPageRoute(builder: (_) => StudentProfilePage(uid: uid));
    }

    // 🔹 Normal routes
    switch (settings.name) {
      case root:
        return MaterialPageRoute(builder: (_) => const SplashGate());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case admin:
        return MaterialPageRoute(builder: (_) => const AdminPage());

      default:
        return _errorRoute("Route not found: ${settings.name}");
    }
  }

  /// 🔴 Error fallback page
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Route error: $message",
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
