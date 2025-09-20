import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/models/app_user.dart';
// ignore: unused_import
import 'package:students_reminder/src/services/attendance_repository.dart';

class HomeRepository {
  final _db = FirebaseFirestore.instance;

  /// 🔹 Fetch all students (optionally filter by group)
  Stream<List<AppUser>> watchStudents({String? group}) {
    Query<Map<String, dynamic>> query = _db.collection('users');

    if (group != null && group.isNotEmpty) {
      query = query.where('courseGroup', isEqualTo: group);
    }

    return query.snapshots().map(
      (snap) =>
          snap.docs.map((doc) => AppUser.fromMap(doc.id, doc.data())).toList(),
    );
  }

  /// 🔹 Backward compatible alias for home_page.dart
  Stream<List<AppUser>> watchAllStudents() {
    return watchStudents();
  }

  /// 🔹 Fetch analytics overview for a student
  Future<Map<String, int>> fetchAttendanceStats(String uid) async {
    final ref = _db.collection('users').doc(uid).collection('attendance');

    final snap = await ref.get();
    int present = 0, late = 0, absent = 0;

    for (var doc in snap.docs) {
      final status = doc['status'] as String?;
      if (status == 'present') {
        present++;
      } else if (status == 'late') {
        late++;
      } else if (status == 'absent') {
        absent++;
      }
    }

    return {'present': present, 'late': late, 'absent': absent};
  }

  /// 🔹 Watch analytics in real-time
  Stream<Map<String, int>> watchAttendanceStats(String uid) {
    final ref = _db.collection('users').doc(uid).collection('attendance');

    return ref.snapshots().map((snap) {
      int present = 0, late = 0, absent = 0;

      for (var doc in snap.docs) {
        final status = doc['status'] as String?;
        if (status == 'present') {
          present++;
        } else if (status == 'late') {
          late++;
        } else if (status == 'absent') {
          absent++;
        }
      }

      return {'present': present, 'late': late, 'absent': absent};
    });
  }
}
