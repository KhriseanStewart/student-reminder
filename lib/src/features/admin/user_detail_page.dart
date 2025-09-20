import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ✅ Custom widgets
import 'package:students_reminder/src/widgets/profile_card.dart';
import 'package:students_reminder/src/widgets/analytics_chart.dart';
import 'package:students_reminder/src/widgets/actions_row.dart';
import 'package:students_reminder/src/widgets/timeline_item.dart';
import 'package:students_reminder/src/widgets/analytics_counters.dart';

// ✅ Models
import 'package:students_reminder/src/models/app_user.dart';

/// A smart attendance detail page that works for both:
/// 1. Admin viewing any student
/// 2. Student viewing their own attendance
class UserDetailPage extends StatefulWidget {
  final AppUser? student; // the profile being viewed (admin flow)
  final String? userId; // student UID (student flow)
  final AppUser currentUser; // 🔑 always the logged-in user

  /// Factory for admin view (admin opens another student's profile)
  const UserDetailPage.admin({
    super.key,
    required this.student,
    required this.currentUser,
  }) : userId = null;

  /// Factory for student view (student views self)
  const UserDetailPage.student({
    super.key,
    required this.userId,
    required this.currentUser,
  }) : student = null;

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  // ────────────────────────── ROLE HELPERS ──────────────────────────
  /// True if logged-in user is admin
  bool get isAdmin => widget.currentUser.role.toLowerCase() == "admin";

  /// True if logged-in user is viewing their own page
  bool get isViewingSelf =>
      widget.userId == widget.currentUser.uid ||
      widget.student?.uid == widget.currentUser.uid;

  // ────────────────────────── FIRESTORE REFS ──────────────────────────
  DocumentReference<Map<String, dynamic>> get _userRef {
    final uid = widget.userId ?? widget.student!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get _attendanceCol =>
      _userRef.collection('attendance');

  // ────────────────────────── FORMAT HELPERS ──────────────────────────
  String _fmtTime(dynamic ts) {
    if (ts == null) return "—";
    try {
      final date = (ts as Timestamp).toDate();
      return DateFormat("hh:mm a").format(date);
    } catch (_) {
      return "—";
    }
  }

  String _fmtDate(dynamic ts) {
    if (ts == null) return "—";
    try {
      final date = (ts as Timestamp).toDate();
      return DateFormat("EEE, MMM d").format(date);
    } catch (_) {
      return "—";
    }
  }

  String _fmtDateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.greenAccent;
      case 'late':
        return Colors.orangeAccent;
      case 'absent':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // ────────────────────────── ACTIONS (restricted) ──────────────────────────
  Future<void> _markStatus(String status) async {
    if (!isAdmin) return; // 🚫 Students cannot mark
    final ref = _attendanceCol.doc(_fmtDateKey(DateTime.now()));
    await ref.set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Marked $status')));
  }

  Future<void> _editLateReason() async {
    if (!isAdmin) return; // 🚫 Students cannot edit
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Late reason', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Type reason',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (res == null) return;

    await _attendanceCol.doc(_fmtDateKey(DateTime.now())).set({
      'status': 'late',
      'lateReason': res.isEmpty ? null : res,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ────────────────────────── ANALYTICS HELPERS ──────────────────────────
  Map<String, int> _tally(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int p = 0, a = 0, l = 0;
    for (final d in docs) {
      final s = (d['status'] ?? '').toString().toLowerCase();
      if (s == 'present') {
        p++;
      } else if (s == 'absent')
        a++;
      else if (s == 'late')
        l++;
    }
    return {'present': p, 'late': l, 'absent': a};
  }

  List<Map<String, dynamic>> _last7docs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final mapById = {for (final d in docs) d.id: d};
    final now = DateTime.now();
    final list = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final key = _fmtDateKey(day);
      final doc = mapById[key];
      final status = (doc != null ? (doc.data()['status'] ?? '') : '')
          .toString()
          .toLowerCase();
      list.add({'day': day, 'status': status});
    }
    return list;
  }

  // ────────────────────────── UI ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.student != null
              ? '${widget.student!.displayName} • Admin View'
              : isViewingSelf
              ? "My Attendance"
              : "Student Attendance",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _attendanceCol
            .orderBy('clockInAt', descending: true)
            .snapshots(),
        builder: (context, attnSnap) {
          if (attnSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          final attnDocs = attnSnap.data?.docs ?? [];
          final counts = _tally(attnDocs);
          final last7 = _last7docs(attnDocs);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ✅ Profile
              if (widget.student != null)
                ProfileCard(student: widget.student!)
              else
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: _userRef.get(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepPurple,
                          ),
                        ),
                      );
                    }
                    final data = snap.data!.data() ?? {};
                    return ProfileCard(
                      student: AppUser.fromMap(_userRef.id, data),
                    );
                  },
                ),

              const SizedBox(height: 16),
              AnalyticsCountersRow(
                present: counts['present'] ?? 0,
                late: counts['late'] ?? 0,
                absent: counts['absent'] ?? 0,
              ),

              const SizedBox(height: 16),
              AnalyticsCharts(
                series: last7
                    .map((e) => e['status'] == 'present' ? 1 : 0)
                    .toList(),
                counts: counts,
              ),

              const SizedBox(height: 16),

              // ✅ Only admins see these action buttons
              if (isAdmin)
                ActionsRow(
                  onPresent: () => _markStatus('present'),
                  onAbsent: () => _markStatus('absent'),
                  onLate: _editLateReason,
                ),

              const SizedBox(height: 16),
              ...attnDocs.map((d) {
                final data = d.data();
                final status = (data['status'] ?? 'unknown').toString();
                final reason = (data['lateReason'] ?? '').toString().trim();
                final loc = (data['location'] as Map<String, dynamic>?);
                final lat = loc?['lat']?.toDouble();
                final lng = loc?['lng']?.toDouble();

                return TimelineItem(
                  prettyDate: _fmtDate(data['clockInAt']),
                  status: status,
                  inTime: _fmtTime(data['clockInAt']),
                  outTime: _fmtTime(data['clockOutAt']),
                  reason: reason.isEmpty ? null : reason,
                  mapLatLng: (lat != null && lng != null)
                      ? LatLng(lat, lng)
                      : null,
                  pillColor: _statusColor(status),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
