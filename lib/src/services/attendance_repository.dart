import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/models/attendance_day.dart';

import 'package:students_reminder/src/models/attendance_stats.dart';

/// Attendance status enum
enum AttendanceStatus { present, late, absent }

/// Handles both student + admin attendance operations
class AttendanceRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  /// Format date as YYYY-MM-DD
  String todayId([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(n);
  }

  /// Reference for today’s attendance document for current user
  DocumentReference<Map<String, dynamic>> todayDocRef([DateTime? now]) {
    final id = todayId(now);
    return _db.collection('users').doc(_uid).collection('attendance').doc(id);
  }

  // ───────────────────────────── STUDENT METHODS ─────────────────────────────

  Stream<AttendanceDay?> watchToday([DateTime? now]) {
    return todayDocRef(now).snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;

      final day = AttendanceDay.fromDoc(doc);

      final cutoff = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        16,
        0,
      );

      if (day.clockInAt != null &&
          day.clockOutAt == null &&
          DateTime.now().isAfter(cutoff)) {
        await doc.reference.update({'clockOutAt': Timestamp.fromDate(cutoff)});
        return day.copyWith(clockOutAt: cutoff);
      }

      return day;
    });
  }

  Stream<List<AttendanceDay>> watchRecentDays({int limit = 7}) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('attendance')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceDay.fromDoc).toList());
  }

  Future<void> clockIn({
    required double lat,
    required double lng,
    String? lateReason,
  }) async {
    final ref = todayDocRef();

    final now = DateTime.now();
    final isLate = now.hour > 8 || (now.hour == 8 && now.minute > 30);
    final status = isLate
        ? AttendanceStatus.late.name
        : AttendanceStatus.present.name;

    await ref.set({
      'date': todayId(),
      'status': status,
      'clockInAt': FieldValue.serverTimestamp(),
      'clockInLoc': {'latitude': lat, 'longitude': lng},
      if (lateReason != null) 'lateReason': lateReason,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'userId': AuthService.instance.currentUser!.uid,
    }, SetOptions(merge: true));
  }

  Future<void> clockOut({required double lat, required double lng}) async {
    final ref = todayDocRef();
    await ref.set({
      'date': todayId(),
      'clockOutAt': FieldValue.serverTimestamp(),
      'clockOutLoc': {'latitude': lat, 'longitude': lng},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ───────────────────────────── ADMIN METHODS ─────────────────────────────

  Stream<List<AttendanceDay>> watchUserAttendance(
    String uid, {
    int limit = 30,
  }) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceDay.fromDoc).toList());
  }

  Stream<List<AttendanceDay>> watchAllAttendance({int limit = 50}) {
    return _db
        .collectionGroup('attendance')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceDay.fromDoc).toList());
  }


/// Stream live updates for user's attendance stats
Stream<AttendanceStats> watchUserStats(String uid) {
  return _db
      .collection('users')
      .doc(uid)
      .collection('attendance')
      .snapshots()
      .map((snapshot) {
        int present = 0, late = 0, absent = 0;

        for (var doc in snapshot.docs) {
          final status = doc['status'];
          if (status == 'present') present++;
          if (status == 'late') late++;
          if (status == 'absent') absent++;
        }

        return AttendanceStats(
          present: present,
          late: late,
          absent: absent,
        );
      });
}

  /// New: Get attendance stats (present, late, absent)
  Future<Map<String, int>> getAttendanceStats(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .get();

    int present = 0;
    int late = 0;
    int absent = 0;

    for (var doc in snapshot.docs) {
      final status = doc['status'];
      if (status == 'present') present++;
      if (status == 'late') late++;
      if (status == 'absent') absent++;
    }

    return {
      'present': present,
      'late': late,
      'absent': absent,
    };
  }
}