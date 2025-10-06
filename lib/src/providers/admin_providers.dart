import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/core/utils/distance_utils.dart'
    as distance_utils;
import 'package:students_reminder/src/models/attendance_record.dart';
import 'package:students_reminder/src/models/geofence_incident.dart';
import 'package:students_reminder/src/providers/incident_providers.dart';
import 'package:students_reminder/src/services/attendance_service.dart';
import 'package:students_reminder/src/services/incident_service.dart';
import 'package:students_reminder/src/services/provider.dart';

class AdminAttendanceSummary {
  const AdminAttendanceSummary({
    required this.records,
    required this.total,
    required this.uniqueStudents,
    required this.present,
    required this.late,
    required this.outside,
    required this.latestByStudent,
    required this.lateCounts,
    required this.outsideCounts,
  });

  final List<AttendanceRecord> records;
  final int total;
  final int uniqueStudents;
  final int present;
  final int late;
  final int outside;
  final Map<String, AttendanceRecord> latestByStudent;
  final Map<String, int> lateCounts;
  final Map<String, int> outsideCounts;

  double get presentRate => uniqueStudents == 0 ? 0 : present / uniqueStudents;
}

final adminTodayRecordsProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final service = ref.watch(attendanceServiceProvider);
  return service.watchAttendanceForDate(date: DateTime.now());
});

final adminTodaySummaryProvider = Provider<AsyncValue<AdminAttendanceSummary>>((
  ref,
) {
  final recordsAsync = ref.watch(adminTodayRecordsProvider);
  return recordsAsync.whenData((records) {
    records.sort((a, b) => a.checkedAt.compareTo(b.checkedAt));
    final present = records
        .where((r) => r.status == distance_utils.AttStatus.present)
        .length;
    final late = records
        .where((r) => r.status == distance_utils.AttStatus.late)
        .length;
    final outside = records
        .where((r) => r.status == distance_utils.AttStatus.outsideAttempt)
        .length;

    final latestByStudent = <String, AttendanceRecord>{};
    final lateCounts = <String, int>{};
    final outsideCounts = <String, int>{};

    for (final record in records) {
      final uid = record.studentUid;
      latestByStudent[uid] = record;

      if (record.status == distance_utils.AttStatus.late) {
        lateCounts.update(uid, (value) => value + 1, ifAbsent: () => 1);
      }

      if (record.status == distance_utils.AttStatus.outsideAttempt) {
        outsideCounts.update(uid, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    return AdminAttendanceSummary(
      records: records,
      total: records.length,
      uniqueStudents: latestByStudent.length,
      present: present,
      late: late,
      outside: outside,
      latestByStudent: latestByStudent,
      lateCounts: lateCounts,
      outsideCounts: outsideCounts,
    );
  });
});

final studentCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(homeRepoProvider);
  return repo.watchStudents().map((students) => students.length);
});

final adminRecentIncidentsProvider =
    Provider<AsyncValue<List<GeofenceIncident>>>(
      (ref) => ref.watch(
        adminIncidentsProvider(
          const IncidentFilters(limit: 10, status: IncidentStatus.open),
        ),
      ),
    );
