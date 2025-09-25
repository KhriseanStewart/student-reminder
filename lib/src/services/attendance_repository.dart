// lib/src/services/attendance_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:students_reminder/src/services/auth_service.dart';

/// Attendance status enum
enum AttendanceStatus { present, late, absent }

/// Model for a single day of attendance
class AttendanceDay {
  AttendanceDay({
    required this.id,
    this.dateId,
    this.status,
    this.clockInAt,
    this.clockOutAt,
    this.clockInLat,
    this.clockInLng,
    this.clockOutLat,
    this.clockOutLng,
    this.lateReason,
    this.userId,
  });

  final String id;
  final String? dateId;
  final String? status;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final double? clockInLat;
  final double? clockInLng;
  final double? clockOutLat;
  final double? clockOutLng;
  final String? lateReason;
  final String? userId;

  factory AttendanceDay.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final clockIn = data['clockInAt'];
    final clockOut = data['clockOutAt'];
    final clockInLoc = data['clockInLoc'] as Map<String, dynamic>?;
    final clockOutLoc = data['clockOutLoc'] as Map<String, dynamic>?;

    return AttendanceDay(
      id: doc.id,
      dateId: data['date'] as String?,
      status: data['status'] as String?,
      clockInAt: clockIn is Timestamp ? clockIn.toDate() : null,
      clockOutAt: clockOut is Timestamp ? clockOut.toDate() : null,
      clockInLat: (clockInLoc?['latitude'] as num?)?.toDouble(),
      clockInLng: (clockInLoc?['longitude'] as num?)?.toDouble(),
      clockOutLat: (clockOutLoc?['latitude'] as num?)?.toDouble(),
      clockOutLng: (clockOutLoc?['longitude'] as num?)?.toDouble(),
      lateReason: data['lateReason'] as String?,
      userId: data['userId'] as String?,
    );
  }

  AttendanceDay copyWith({
    String? status,
    DateTime? clockOutAt,
    double? clockOutLat,
    double? clockOutLng,
  }) {
    return AttendanceDay(
      id: id,
      dateId: dateId,
      status: status ?? this.status,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt ?? this.clockOutAt,
      clockInLat: clockInLat,
      clockInLng: clockInLng,
      clockOutLat: clockOutLat ?? this.clockOutLat,
      clockOutLng: clockOutLng ?? this.clockOutLng,
      lateReason: lateReason,
      userId: userId,
    );
  }
}

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

  /// Watch today’s attendance (null if not clocked in).
  /// 🔹 Includes **auto clock-out at 4:00 PM**
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
        // Force clock-out
        await doc.reference.update({'clockOutAt': Timestamp.fromDate(cutoff)});
        return day.copyWith(clockOutAt: cutoff);
      }

      return day;
    });
  }

  /// Watch recent attendance history for logged-in student
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

  /// Clock in (auto-detects present/late)
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

  /// Clock out
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

  /// Watch attendance for a specific student
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

  /// Watch all students’ attendance (for dashboard/overview)
  Stream<List<AttendanceDay>> watchAllAttendance({int limit = 50}) {
    return _db
        .collectionGroup('attendance')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceDay.fromDoc).toList());
  }
}
