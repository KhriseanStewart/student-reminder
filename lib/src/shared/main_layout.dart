import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/features/home/home_page.dart';
import 'package:students_reminder/src/features/notes/my_notes_page.dart';
import 'package:students_reminder/src/features/profile/profile_page.dart';
import 'package:students_reminder/src/features/attendance/attendance_page.dart';
import 'package:students_reminder/src/features/admin/admin.dart';

class MainLayoutPage extends StatefulWidget {
  final User? user; // 🔑 pass logged-in user

  const MainLayoutPage({super.key, required this.user});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Always show base student tabs
    final pages = [
      const HomePage(),
      const MyNotesPage(),
      const AttendancePage(),
      const ProfilePage(),
    ];

    final destinations = [
      const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      const NavigationDestination(icon: Icon(Icons.event_note), label: 'Notes'),
      const NavigationDestination(icon: Icon(Icons.access_time), label: 'Attendance'),
      const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: destinations,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}