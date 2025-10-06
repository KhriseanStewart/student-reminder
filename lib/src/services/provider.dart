import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/services/home_repository.dart';
import 'package:students_reminder/src/services/attendance_repository.dart';

final homeRepoProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

final attendanceRepoProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});
