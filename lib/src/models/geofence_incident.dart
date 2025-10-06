import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/core/utils/distance_utils.dart'
    as distance_utils;
import 'package:students_reminder/src/models/attendance_record.dart';
import 'package:students_reminder/src/models/geofence_profile.dart';

enum IncidentStatus { open, acknowledged }

IncidentStatus _incidentStatusFromString(String? raw) {
  switch (raw) {
    case 'acknowledged':
      return IncidentStatus.acknowledged;
    case 'open':
    default:
      return IncidentStatus.open;
  }
}

class GeofenceIncident {
  const GeofenceIncident({
    required this.id,
    required this.studentUid,
    required this.direction,
    required this.occurredAt,
    required this.actualLocation,
    required this.designatedLocation,
    required this.distanceMeters,
    required this.bandType,
    required this.status,
    this.sessionId,
    this.classId,
    this.outsideMessageText,
    this.outsideMessageShown = false,
    this.accuracyMeters,
    this.outsidePolicyApplied,
  });

  final String id;
  final String studentUid;
  final AttendanceDirection direction;
  final DateTime occurredAt;
  final GeoSample actualLocation;
  final Geofence designatedLocation;
  final double distanceMeters;
  final double? accuracyMeters;
  final BandType bandType;
  final IncidentStatus status;
  final String? sessionId;
  final String? classId;
  final String? outsideMessageText;
  final bool outsideMessageShown;
  final OutsidePolicy? outsidePolicyApplied;

  String get distanceLabel => distance_utils.prettyDistance(distanceMeters);

  factory GeofenceIncident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final actual = GeoSample.fromMap(
      data['actualLocation'] as Map<String, dynamic>?,
    );
    final designated = Geofence(
      latitude: (data['designatedLocation']?['lat'] as num?)?.toDouble() ?? 0,
      longitude: (data['designatedLocation']?['lng'] as num?)?.toDouble() ?? 0,
      radiusMeters:
          (data['designatedLocation']?['radiusMeters'] as num?)?.toDouble() ??
          0,
      campusSlug: data['designatedLocation']?['campusSlug'] as String?,
    );

    return GeofenceIncident(
      id: doc.id,
      studentUid: data['studentUid'] as String? ?? '',
      sessionId: data['sessionId'] as String?,
      classId: data['classId'] as String?,
      direction:
          _directionFromString(data['direction'] as String?) ??
          AttendanceDirection.checkIn,
      occurredAt:
          (data['occurredAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      actualLocation: actual,
      designatedLocation: designated,
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (data['actualLocation']?['accuracy'] as num?)?.toDouble(),
      bandType:
          bandTypeFromString(data['bandTypeAtTime'] as String?) ??
          BandType.fixed,
      status: _incidentStatusFromString(data['status'] as String?),
      outsideMessageText: data['outsideMessageText'] as String?,
      outsideMessageShown: data['outsideMessageShown'] as bool? ?? false,
      outsidePolicyApplied: outsidePolicyFromString(
        data['outsidePolicyApplied'] as String?,
      ),
    );
  }
}

AttendanceDirection? _directionFromString(String? raw) {
  switch (raw) {
    case 'checkin':
      return AttendanceDirection.checkIn;
    case 'checkout':
      return AttendanceDirection.checkOut;
    default:
      return null;
  }
}
