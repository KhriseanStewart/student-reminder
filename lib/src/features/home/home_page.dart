import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// data
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/services/provider.dart';

// widgets
import 'package:students_reminder/src/widgets/student_card.dart';
import 'package:students_reminder/src/widgets/quick_action.dart';
import 'package:students_reminder/src/widgets/section_title.dart';
import 'package:students_reminder/src/widgets/analytics_overview.dart';
import 'package:students_reminder/src/widgets/empty_state.dart';
import 'package:students_reminder/src/widgets/profile_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(homeRepoProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: repo.watchStudents(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            );
          }

          if (snap.hasError) {
            return EmptyState(
              message: "Failed to load students.\n${snap.error}",
              action: TextButton(
                onPressed: () => (context as Element).markNeedsBuild(),
                child: const Text("Retry"),
              ),
            );
          }

          final students = snap.data ?? <AppUser>[];
          if (students.isEmpty) {
            return const EmptyState(
              message: "No students yet. Add students to get started!",
            );
          }

          // 🔹 Current user from Firestore
          final currentUser = students.firstWhere(
            (s) => s.uid == currentUid,
            orElse: () => students.first,
          );

          // 🔹 Group remaining students by course
          final grouped = <String, List<AppUser>>{};
          for (final s in students) {
            grouped.putIfAbsent(s.courseGroup, () => []).add(s);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profile Card (header)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurpleAccent, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: ProfileCard(student: currentUser),
              ),
              const SizedBox(height: 24),

              // ── Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  QuickAction(
                    icon: Icons.note,
                    label: "Notes",
                    onTap: () {
                      // TODO: Navigate to NotesPage
                      debugPrint("Notes clicked");
                    },
                  ),
                  QuickAction(
                    icon: Icons.access_time,
                    label: "Attendance",
                    onTap: () {
                      // TODO: Navigate to AttendancePage
                      debugPrint("Attendance clicked");
                    },
                  ),
                  QuickAction(
                    icon: Icons.person,
                    label: "Profile",
                    onTap: () {
                      // TODO: Navigate to ProfilePage
                      debugPrint("Profile clicked");
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Analytics
              const SectionTitle(title: "Analytics Overview"),
              const SizedBox(height: 12),
              const AnalyticsOverview(),
              const SizedBox(height: 24),

              // ── Students Section
              const SectionTitle(title: "Students"),
              const SizedBox(height: 12),

              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                ...entry.value.map(
                  (u) => StudentCard(
                    student: u,
                    onTap: () {
                      // TODO: Navigate to UserDetailPage(u.uid)
                      debugPrint("Tapped ${u.displayName} (${u.uid})");
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}