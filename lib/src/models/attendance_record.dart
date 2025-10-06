import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/core/utils/distance_utils.dart'
    as distance_utils;
import 'package:students_reminder/src/models/geofence_profile.dart';

enum AttendanceDirection { checkIn, checkOut }

AttendanceDirection _directionFromString(String? raw) {
  switch (raw) {
    case 'checkin':
      return AttendanceDirection.checkIn;
    case 'checkout':
      return AttendanceDirection.checkOut;
    default:
      return AttendanceDirection.checkIn;
  }
}

distance_utils.AttStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'late':
      return distance_utils.AttStatus.late;
    case 'outsideAttempt':
      return distance_utils.AttStatus.outsideAttempt;
    case 'present':
    default:
      return distance_utils.AttStatus.present;
  }
}

class GeoSample {
  const GeoSample({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  factory GeoSample.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const GeoSample(latitude: 0, longitude: 0);
    }
    return GeoSample(
      latitude:
          (data['lat'] as num?)?.toDouble() ??
          (data['latitude'] as num?)?.toDouble() ??
          0,
      longitude:
          (data['lng'] as num?)?.toDouble() ??
          (data['longitude'] as num?)?.toDouble() ??
          0,
      accuracyMeters: (data['accuracy'] as num?)?.toDouble(),
    );
  }
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.studentUid,
    required this.sessionId,
    required this.direction,
    required this.status,
    required this.checkedAt,
    required this.actualLocation,
    required this.designatedLocation,
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.bandType,
    this.classId,
    this.incidentId,
    this.outsideMessageText,
    this.outsidePolicyApplied,
    this.lateReason,
  });

  final String? lateReason;
  final String id;
  final String studentUid;
  final String sessionId;
  final String? classId;
  final AttendanceDirection direction;
  final distance_utils.AttStatus status;
  final DateTime checkedAt;
  final GeoSample actualLocation;
  final Geofence designatedLocation;
  final double distanceMeters;
  final double accuracyMeters;
  final BandType bandType;
  final String? incidentId;
  final String? outsideMessageText;
  final OutsidePolicy? outsidePolicyApplied;

  String get distanceLabel => distance_utils.prettyDistance(distanceMeters);

  factory AttendanceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    final designated = Geofence(
      latitude: (data['designatedLocation']?['lat'] as num?)?.toDouble() ?? 0,
      longitude: (data['designatedLocation']?['lng'] as num?)?.toDouble() ?? 0,
      radiusMeters:
          (data['designatedLocation']?['radiusMeters'] as num?)?.toDouble() ??
          0,
      campusSlug: data['designatedLocation']?['campusSlug'] as String?,
    );

    final bandType =
        bandTypeFromString(data['bandTypeAtTime'] as String?) ?? BandType.fixed;

    return AttendanceRecord(
      id: doc.id,
      studentUid: data['studentUid'] as String? ?? '',
      sessionId: data['sessionId'] as String? ?? '',
      classId: data['classId'] as String?,
      direction: _directionFromString(data['direction'] as String?),
      status: _statusFromString(data['status'] as String?),
      checkedAt:
          (data['checkedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      actualLocation: GeoSample.fromMap(
        data['deviceLocation'] as Map<String, dynamic>?,
      ),
      designatedLocation: designated,
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0,
      accuracyMeters:
          (data['deviceLocation']?['accuracy'] as num?)?.toDouble() ?? 0,
      bandType: bandType,
      incidentId: data['incidentId'] as String?,
      outsideMessageText: data['outsideMessageText'] as String?,
      outsidePolicyApplied: outsidePolicyFromString(
        data['outsidePolicyApplied'] as String?,
      ),
      lateReason: data['reason'] as String?, // ✅ put it here
    );
  }
}
