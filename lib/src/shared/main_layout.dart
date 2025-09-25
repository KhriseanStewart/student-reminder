import 'package:flutter/material.dart';
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/features/home/home_page.dart';
import 'package:students_reminder/src/features/notes/my_notes_page.dart';
import 'package:students_reminder/src/features/profile/profile_page.dart';
import 'package:students_reminder/src/features/attendance/attendance_page.dart';
import 'package:students_reminder/src/features/admin/admin.dart';

class MainLayoutPage extends StatefulWidget {
  final AppUser user; // 🔑 logged-in user

  const MainLayoutPage({super.key, required this.user});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _index = 0;

  void _setIndex(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    // Base student tabs
    final pages = [
      HomePage(onTabChange: _setIndex, user: widget.user), // 👈 pass callback + user
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

    // If admin → add Admin tab
    if (widget.user.isAdmin) {
      pages.add(const AdminPage());
      destinations.add(
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: destinations,
        onDestinationSelected: _setIndex,
      ),
    );
  }
}