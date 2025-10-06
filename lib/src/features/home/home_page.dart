import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:students_reminder/src/widgets/late_reason_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// data
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/models/attendance_record.dart';
import 'package:students_reminder/src/services/provider.dart';
import 'package:students_reminder/src/features/checkin/check_in_controller.dart';
import 'package:students_reminder/src/features/checkin/check_result_feedback.dart';
import 'package:students_reminder/src/features/checkin/session_context.dart';
import 'package:students_reminder/src/providers/incident_providers.dart';

// widgets
import 'package:students_reminder/src/widgets/student_card.dart';
import 'package:students_reminder/src/features/home/widgets/quick_action.dart';
import 'package:students_reminder/src/widgets/section_title.dart';
import 'package:students_reminder/src/widgets/empty_state.dart';
import 'package:students_reminder/src/features/home/widgets/clock_pill.dart';
import 'package:students_reminder/src/widgets/analytics_overview.dart';

// placeholder pages
import 'package:students_reminder/src/features/courses/courses_page.dart';
import 'package:students_reminder/src/features/assignments/assignments_page.dart';
import 'package:students_reminder/src/features/grades/grades_page.dart';
import 'package:students_reminder/src/features/calendar/calendar_page.dart';

import 'widgets/home_header.dart';

class HomePage extends ConsumerStatefulWidget {
  final AppUser user;
  final void Function(int)? onTabChange;

  const HomePage({super.key, required this.user, this.onTabChange});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final SearchController _searchController = SearchController();
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCheck({
    required bool isCheckIn,
    required SessionContext session,
  }) async {
    final controller = ref.read(checkInControllerProvider.notifier);
    final now = DateTime.now();

    try {
      // 👇 check lateness if clocking in
      if (isCheckIn) {
        final cutoff = session.scheduledStart.add(
          Duration(minutes: session.graceMinutes),
        );
        final isLate = now.isAfter(cutoff);

        if (isLate) {
          final reason = await showLateReasonDialog(context);
          if (reason == null || reason.trim().isEmpty) {
            _showSnack('Clock-in cancelled (no reason provided).');
            return;
          }

          // (Optional) Save to Firestore so it's in the attendance record
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('attendance_records')
                .add({
                  'timestamp': now,
                  'status': 'late',
                  'reason': reason,
                  'classId': session.classId,
                  'sessionId': session.sessionId,
                });
          }

          _showSnack('Late reason saved: $reason');
        }
      }

      // 👇 proceed with check-in/out as usual
      final result = isCheckIn
          ? await controller.checkIn(
              sessionId: session.sessionId,
              classId: session.classId,
              scheduledStart: session.scheduledStart,
              graceMinutes: session.graceMinutes,
            )
          : await controller.checkOut(
              sessionId: session.sessionId,
              classId: session.classId,
              scheduledStart: session.scheduledStart,
              graceMinutes: session.graceMinutes,
            );

      if (!mounted) return;
      showCheckResultFeedback(context, result);
    } on CheckInException catch (err) {
      _showSnack(err.message);
    } catch (_) {
      _showSnack(
        'Failed to ${isCheckIn ? 'clock in' : 'clock out'}. Please try again.',
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  bool _isCurrentlyClockedIn(List<AttendanceRecord> records) {
    final now = DateTime.now();
    AttendanceRecord? lastIn;
    AttendanceRecord? lastOut;

    for (final record in records) {
      if (!_isSameDay(record.checkedAt, now)) continue;
      if (record.direction == AttendanceDirection.checkIn) {
        if (lastIn == null || record.checkedAt.isAfter(lastIn.checkedAt)) {
          lastIn = record;
        }
      } else {
        if (lastOut == null || record.checkedAt.isAfter(lastOut.checkedAt)) {
          lastOut = record;
        }
      }
    }

    if (lastIn == null) return false;
    if (lastOut == null) return true;
    return lastIn.checkedAt.isAfter(lastOut.checkedAt);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(homeRepoProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

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
              message: "Failed to load students.\n\${snap.error}",
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

          final filtered = students.where((s) {
            final q = _query;
            return s.displayName.toLowerCase().contains(q) ||
                s.courseGroup.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q);
          }).toList();

          final grouped = <String, List<AppUser>>{};
          for (final s in filtered) {
            grouped.putIfAbsent(s.courseGroup, () => []).add(s);
          }

          if (_query.isNotEmpty && grouped.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "No matching students.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            );
          }

          final session = ref.watch(sessionContextProvider);
          final checkState = ref.watch(checkInControllerProvider);

          final attendanceHistory = currentUid != null
              ? ref.watch(attendanceHistoryProvider(currentUid))
              : const AsyncData<List<AttendanceRecord>>(<AttendanceRecord>[]);

          var isClockedIn = false;
          attendanceHistory.when(
            data: (records) => isClockedIn = _isCurrentlyClockedIn(records),
            error: (_, __) {},
            loading: () {},
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ClipPath(
                  clipper: EdgeCurveClipper(),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 48, bottom: 24),
                    child: HomeHeader(
                      displayName: currentUser.displayName,
                      photoUrl: currentUser.photoUrl ?? '',
                      searchBar: SearchAnchor.bar(
                        searchController: _searchController,
                        barHintText: 'Search students...',
                        barLeading: const SizedBox.shrink(),
                        barTrailing: const [
                          Icon(Icons.search, color: Colors.white70),
                        ],
                        onChanged: (val) {
                          final text = val.trim().toLowerCase();
                          if (_query != text) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _query = text);
                              }
                            });
                          }
                        },
                        suggestionsBuilder: (context, controller) {
                          final query = controller.text.trim().toLowerCase();
                          final suggestions = repo.latestStudents.where((s) {
                            return s.displayName.toLowerCase().contains(
                                  query,
                                ) ||
                                s.email.toLowerCase().contains(query) ||
                                s.courseGroup.toLowerCase().contains(query);
                          }).toList();

                          return suggestions.map((s) {
                            return Material(
                              child: ListTile(
                                title: Text(s.displayName),
                                subtitle: Text(s.courseGroup),
                                onTap: () {
                                  controller.closeView(s.displayName);
                                  setState(
                                    () => _query = s.displayName.toLowerCase(),
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                      ),
                      quickActions: SizedBox(
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ClockPill(
                                isClockedIn: isClockedIn,
                                isLoading: checkState.isLoading,
                                onClockIn: () => _handleCheck(
                                  isCheckIn: true,
                                  session: session,
                                ),
                                onClockOut: () => _handleCheck(
                                  isCheckIn: false,
                                  session: session,
                                ),
                              ),
                            ),
                            QuickAction(
                              icon: Icons.book,
                              label: 'Courses',
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
                              label: 'Assignments',
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
                              label: 'Grades',
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
                              label: 'Calendar',
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
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: const Color(0xFF242424),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 10,
                    shadowColor: Colors.black45,
                    child: const AnalyticsOverview(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Students'),
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
                                  debugPrint('Tapped \${u.displayName}'),
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
      ),
    );
  }
}

class EdgeCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 40.0;

    path.moveTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
