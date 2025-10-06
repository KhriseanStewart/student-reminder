// lib/src/models/attendance_stats.dart
class AttendanceStats {
  final int present;
  final int late;
  final int absent;

  const AttendanceStats({
    this.present = 0,
    this.late = 0,
    this.absent = 0,
  });

  factory AttendanceStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AttendanceStats();
    return AttendanceStats(
      present: (map['present'] ?? 0) as int,
      late: (map['late'] ?? 0) as int,
      absent: (map['absent'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'present': present,
      'late': late,
      'absent': absent,
    };
  }
}