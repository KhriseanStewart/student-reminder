import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:students_reminder/src/features/home/home_page.dart';
import 'package:students_reminder/src/features/notes/my_notes_page.dart';
import 'package:students_reminder/src/features/profile/profile_page.dart';
import 'package:students_reminder/src/features/attendance/attendance_page.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/models/app_user.dart';

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _index = 0;
  AppUser? _appUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final appUser = AppUser.fromMap(user.uid, data);

    if (!mounted) return;

    setState(() {
      _appUser = appUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanged(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const Scaffold(
            body: Center(child: Text('User not logged in')),
          );
        }

        if (_appUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pages = [
          HomePage(
            user: _appUser!,
            onTabChange: (int i) => setState(() => _index = i), // ✅ Add this
          ),
          const MyNotesPage(),
          const AttendancePage(),
          ProfilePage(user: _appUser!),
        ];
        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                icon: Icon(Icons.event_note),
                label: 'Notes',
              ),
              NavigationDestination(
                icon: Icon(Icons.access_time),
                label: 'Attendance',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
            onDestinationSelected: (i) => setState(() => _index = i),
          ),
        );
      },
    );
  }
}
