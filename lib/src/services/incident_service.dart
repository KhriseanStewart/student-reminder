import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/models/geofence_incident.dart';
import 'package:students_reminder/src/models/geofence_profile.dart';

class IncidentFilters {
  const IncidentFilters({
    this.studentUid,
    this.start,
    this.end,
    this.bandType,
    this.status,
    this.limit = 20,
  });

  final String? studentUid;
  final DateTime? start;
  final DateTime? end;
  final BandType? bandType;
  final IncidentStatus? status;
  final int limit;
}

class IncidentService {
  IncidentService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<GeofenceIncident>> watchIncidents({
    IncidentFilters filters = const IncidentFilters(),
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('geofence_incidents')
        .orderBy('occurredAt', descending: true);

    if (filters.studentUid != null) {
      query = query.where('studentUid', isEqualTo: filters.studentUid);
    }

    if (filters.start != null) {
      query = query.where(
        'occurredAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filters.start!),
      );
    }

    if (filters.end != null) {
      query = query.where(
        'occurredAt',
        isLessThanOrEqualTo: Timestamp.fromDate(filters.end!),
      );
    }

    if (filters.bandType != null) {
      query = query.where('bandTypeAtTime', isEqualTo: filters.bandType!.name);
    }

    if (filters.status != null) {
      query = query.where('status', isEqualTo: filters.status!.name);
    }

    query = query.limit(filters.limit);

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(GeofenceIncident.fromDoc).toList(growable: false),
    );
  }

  Future<List<GeofenceIncident>> fetchIncidents({
    IncidentFilters filters = const IncidentFilters(),
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('geofence_incidents')
        .orderBy('occurredAt', descending: true);

    if (filters.studentUid != null) {
      query = query.where('studentUid', isEqualTo: filters.studentUid);
    }

    if (filters.start != null) {
      query = query.where(
        'occurredAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filters.start!),
      );
    }

    if (filters.end != null) {
      query = query.where(
        'occurredAt',
        isLessThanOrEqualTo: Timestamp.fromDate(filters.end!),
      );
    }

    if (filters.bandType != null) {
      query = query.where('bandTypeAtTime', isEqualTo: filters.bandType!.name);
    }

    if (filters.status != null) {
      query = query.where('status', isEqualTo: filters.status!.name);
    }

    query = query.limit(filters.limit);

    final snapshot = await query.get();
    return snapshot.docs.map(GeofenceIncident.fromDoc).toList(growable: false);
  }
}

final incidentServiceProvider = Provider<IncidentService>((ref) {
  return IncidentService();
});
