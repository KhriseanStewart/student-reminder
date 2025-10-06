import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/models/attendance_record.dart';

class AttendanceService {
  AttendanceService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<AttendanceRecord>> watchStudentAttendance({
    required String studentUid,
    int limit = 7,
    DateTime? start,
    DateTime? end,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('attendance')
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('checkedAt', descending: true)
        .limit(limit);

    if (start != null) {
      query = query.where(
        'checkedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }

    if (end != null) {
      query = query.where(
        'checkedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(end),
      );
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(AttendanceRecord.fromDoc).toList(growable: false),
    );
  }

  Future<List<AttendanceRecord>> fetchStudentAttendance({
    required String studentUid,
    int limit = 20,
    DateTime? start,
    DateTime? end,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('attendance')
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('checkedAt', descending: true)
        .limit(limit);

    if (start != null) {
      query = query.where(
        'checkedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }

    if (end != null) {
      query = query.where(
        'checkedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(end),
      );
    }

    final snapshot = await query.get();
    return snapshot.docs.map(AttendanceRecord.fromDoc).toList(growable: false);
  }

  Stream<List<AttendanceRecord>> watchAttendanceForDate({
    required DateTime date,
  }) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    Query<Map<String, dynamic>> query = _db
        .collection('attendance')
        .where('checkedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('checkedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('checkedAt');

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(AttendanceRecord.fromDoc).toList(growable: false),
    );
  }
}

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});
