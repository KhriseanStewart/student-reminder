import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Models
import 'package:students_reminder/src/models/app_user.dart';

// ✅ Screens
import 'package:students_reminder/src/shared/main_layout.dart';
import 'package:students_reminder/src/features/intro/intro_screen.dart';
import 'package:students_reminder/src/features/auth/login_page.dart';
import 'package:students_reminder/src/features/auth/register_page.dart';

// ✅ Services
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/services/session_manager.dart';

/// ──────────────────────────
/// SplashGate
/// Decides what screen to show when app starts:
///   1. If no Firebase user:
///        → If intro not seen → Splash → Intro
///        → If intro seen → LoginPage
///   2. If Firebase user exists:
///        → If Firestore profile missing → RegisterPage
///        → If profile exists → MainLayoutPage (role-aware)
/// ──────────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  /// Fetch Firestore profile
  Future<AppUser?> _fetchAppUser(User? user) async {
    if (user == null) return null;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!snap.exists) {
      debugPrint("⚠️ Firestore profile missing for user: ${user.uid}");
      return null;
    }
    debugPrint("✅ Firestore profile found for user: ${user.uid}");
    return AppUser.fromMap(user.uid, snap.data()!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SessionManager.isExpired(), // ⏳ Check if session expired
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🚨 If expired → logout
        if (snap.data == true) {
          debugPrint("⏰ Session expired → Logging out user.");
          AuthService.instance.logout();
        }

        // 🔑 Step 1: check if intro was already seen
        return FutureBuilder<bool>(
          future: SessionManager.hasSeenIntro(),
          builder: (context, introSnap) {
            if (!introSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final seenIntro = introSnap.data ?? false;
            debugPrint("👀 Intro seen? $seenIntro");

            // 🔑 Step 2: listen for Firebase auth state
            return StreamBuilder<User?>(
              stream: AuthService.instance.authStateChanged(),
              builder: (context, authSnap) {
                if (authSnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final user = authSnap.data;

                // Case A: No user logged in
                if (user == null) {
                  if (seenIntro) {
                    debugPrint("🚪 No Firebase user + Intro seen → LoginPage");
                    return const LoginPage();
                  } else {
                    debugPrint(
                      "🚪 No Firebase user + Intro NOT seen → SplashScreen → IntroScreen",
                    );
                    return const SplashScreen();
                  }
                }

                // Case B: User logged in → fetch Firestore profile
                debugPrint("🔑 Firebase user logged in: ${user.uid}");
                return FutureBuilder<AppUser?>(
                  future: _fetchAppUser(user),
                  builder: (context, userSnap) {
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final appUser = userSnap.data;

                    // 🚨 If profile missing → go to RegisterPage
                    if (appUser == null) {
                      debugPrint(
                        "⚠️ User logged in but no Firestore profile → RegisterPage",
                      );
                      return const RegisterPage();
                    }

                    // ✅ Profile exists → go to MainLayout
                    debugPrint(
                      "🎉 User logged in + Profile exists → MainLayoutPage",
                    );
                    return MainLayoutPage(user: appUser);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// ──────────────────────────
/// SplashScreen
/// Only shown on very first launch (user == null & intro not seen).
/// Animates → IntroScreen
/// ──────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeIn = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
    _navigateToIntro();
  }

  /// After 3s → navigate to IntroScreen
  void _navigateToIntro() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    debugPrint("➡️ Splash finished → Navigating to IntroScreen");
    Navigator.of(context).pushReplacement(_createFadeRoute());
  }

  Route _createFadeRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const IntroScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: FadeTransition(
        opacity: _fadeIn,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Thanks for choosing your',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 10),
              Icon(Icons.menu_book, size: 100, color: Colors.amber),
              SizedBox(height: 20),
              Text(
                'Student Reminder',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
