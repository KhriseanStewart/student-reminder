import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// data
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/services/provider.dart';
import 'package:students_reminder/src/services/attendance_repository.dart';
import 'package:students_reminder/src/services/location_service.dart';

// widgets
import 'package:students_reminder/src/widgets/student_card.dart';
import 'package:students_reminder/src/features/home/widgets/quick_action.dart';
import 'package:students_reminder/src/widgets/section_title.dart';
import 'package:students_reminder/src/widgets/analytics_overview.dart';
import 'package:students_reminder/src/widgets/empty_state.dart';
import 'package:students_reminder/src/features/home/widgets/app_bar.dart';
import 'package:students_reminder/src/features/profile/widgets/profile_card.dart';
import 'package:students_reminder/src/features/home/widgets/clock_pill.dart';
import 'package:students_reminder/src/widgets/late_reason_dialog.dart';
import 'package:students_reminder/src/features/home/widgets/search_bar.dart';

// placeholder pages
import 'package:students_reminder/src/features/courses/courses_page.dart';
import 'package:students_reminder/src/features/assignments/assignments_page.dart';
import 'package:students_reminder/src/features/grades/grades_page.dart';
import 'package:students_reminder/src/features/calendar/calendar_page.dart';
import 'package:students_reminder/src/features/settings/settings_page.dart'; // ✅ new

class HomePage extends ConsumerStatefulWidget {
  final AppUser user;
  final void Function(int)? onTabChange;

  const HomePage({super.key, required this.user, this.onTabChange});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(homeRepoProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final attendanceRepo = AttendanceRepository();

    return Scaffold(
      backgroundColor: Colors.black,
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

          final currentUser = students.firstWhere(
            (s) => s.uid == currentUid,
            orElse: () => students.first,
          );

          final q = _query.toLowerCase();
          final filtered = students.where((s) {
            return s.displayName.toLowerCase().contains(q) ||
                s.courseGroup.toLowerCase().contains(q);
          }).toList();

          final grouped = <String, List<AppUser>>{};
          for (final s in filtered) {
            grouped.putIfAbsent(s.courseGroup, () => []).add(s);
          }

          return StreamBuilder<AttendanceDay?>(
            stream: attendanceRepo.watchToday(),
            builder: (context, attendanceSnap) {
              final today = attendanceSnap.data;
              final isClockedIn =
                  today?.clockInAt != null && today?.clockOutAt == null;

              return CustomScrollView(
                slivers: [
                  const AppBarX(),

                  // 🔹 Profile Card (with gear icon)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ProfileCard(
                        name: currentUser.displayName,
                        role: currentUser.courseGroup,
                        photoUrl: currentUser.photoUrl,
                        onTap: () =>
                            widget.onTabChange?.call(3), // go profile tab
                        onSettingsTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(), // ✅
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 🔹 Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SearchBarX(
                        onChanged: (val) => setState(() => _query = val),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Quick Actions row
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          // ClockPill
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClockPill(
                              isClockedIn: isClockedIn,
                              onClockIn: () async {
                                final now = DateTime.now();
                                final pos = await LocationService()
                                    .getCurrentPosition();

                                String? lateReason;
                                if (now.hour > 8 ||
                                    (now.hour == 8 && now.minute > 30)) {
                                  lateReason = await showLateReasonDialog(
                                    context,
                                  );
                                  if (lateReason == null ||
                                      lateReason.trim().isEmpty)
                                    return;
                                }

                                await attendanceRepo.clockIn(
                                  lat: pos.latitude,
                                  lng: pos.longitude,
                                  lateReason: lateReason,
                                );

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Clocked In ✅ (synced record)",
                                    ),
                                  ),
                                );
                              },
                              onClockOut: () async {
                                final pos = await LocationService()
                                    .getCurrentPosition();
                                await attendanceRepo.clockOut(
                                  lat: pos.latitude,
                                  lng: pos.longitude,
                                );

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Clocked Out ⏹"),
                                  ),
                                );
                              },
                            ),
                          ),

                          QuickAction(
                            icon: Icons.book,
                            label: "Courses",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoursesPage(),
                              ),
                            ),
                            variant: QuickActionVariant.glass,
                          ),
                          QuickAction(
                            icon: Icons.assignment,
                            label: "Assignments",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AssignmentsPage(),
                              ),
                            ),
                            variant: QuickActionVariant.glass,
                          ),
                          QuickAction(
                            icon: Icons.bar_chart,
                            label: "Grades",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GradesPages(),
                              ),
                            ),
                            variant: QuickActionVariant.glass,
                          ),
                          QuickAction(
                            icon: Icons.calendar_today,
                            label: "Calendar",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalendarPage(),
                              ),
                            ),
                            variant: QuickActionVariant.glass,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Analytics Overview
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SectionTitle(title: "Analytics Overview"),
                          SizedBox(height: 12),
                          AnalyticsOverview(),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Students Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(title: "Students"),
                          const SizedBox(height: 12),
                          for (final entry in grouped.entries) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
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
                              (u) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: StudentCard(
                                  student: u,
                                  onTap: () =>
                                      debugPrint("Tapped ${u.displayName}"),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
