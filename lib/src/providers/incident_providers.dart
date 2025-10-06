import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/models/attendance_record.dart';
import 'package:students_reminder/src/models/geofence_incident.dart';
import 'package:students_reminder/src/services/attendance_service.dart';
import 'package:students_reminder/src/services/incident_service.dart';

final attendanceHistoryProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, uid) {
      final service = ref.read(attendanceServiceProvider);
      return service.watchStudentAttendance(studentUid: uid);
    });

final studentIncidentsProvider =
    StreamProvider.family<List<GeofenceIncident>, String>((ref, uid) {
      final service = ref.read(incidentServiceProvider);
      return service.watchIncidents(
        filters: IncidentFilters(studentUid: uid, limit: 20),
      );
    });

final adminIncidentsProvider =
    StreamProvider.family<List<GeofenceIncident>, IncidentFilters>((
      ref,
      filters,
    ) {
      final service = ref.read(incidentServiceProvider);
      return service.watchIncidents(filters: filters);
    });
