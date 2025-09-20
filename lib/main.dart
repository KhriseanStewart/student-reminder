import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/core/app_theme.dart';
import 'package:students_reminder/src/core/bootstrap.dart';
import 'package:students_reminder/src/shared/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();

  // ⚠️ Run this ONCE to backfill missing roles, then REMOVE it
  // await migrateUsersRoles();

  runApp(const ProviderScope(child: StudentsReminderApp()));
}

class StudentsReminderApp extends StatelessWidget {
  const StudentsReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Students Reminder',
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,

      // ✅ Only use route system (no home:)
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.root, // 🔑 Always start at SplashGate
    );
  }
}