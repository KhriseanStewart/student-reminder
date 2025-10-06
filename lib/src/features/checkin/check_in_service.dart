import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/models/check_result.dart';
import 'package:students_reminder/src/models/geofence_profile.dart';

class CheckStoreResult {
  const CheckStoreResult({
    required this.checkResult,
    this.attendanceId,
    this.incidentId,
  });

  final CheckResult checkResult;
  final String? attendanceId;
  final String? incidentId;

  bool get hasAttendance => attendanceId != null;
  bool get hasIncident => incidentId != null;
}

final checkInPersistenceProvider = Provider<CheckInPersistenceService>(
  (ref) => CheckInPersistenceService(),
);

class CheckInPersistenceService {
  CheckInPersistenceService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<CheckStoreResult> persist({
  required CheckResult result,
  required String studentUid,
  required String sessionId,
  String? classId,
}) async {
  try {
    // Sanity check: ensure geofence exists before using it
    if (result.designatedGeofence == null) {
      throw Exception('Missing designated geofence for check-in');
    }

    final direction = result.isCheckIn ? 'checkin' : 'checkout';
    DocumentReference<Map<String, dynamic>>? incidentRef;

    // Create incident if necessary
    if (result.isOutside && result.bandType == BandType.fixed) {
      incidentRef = await _createIncident(
        result: result,
        studentUid: studentUid,
        sessionId: sessionId,
        classId: classId,
        direction: direction,
      );
    }

    DocumentReference<Map<String, dynamic>>? attendanceRef;

    if (result.decision == CheckDecision.allow) {
      attendanceRef = _db.collection('attendance').doc();

      await attendanceRef.set({
        'sessionId': sessionId,
        if (classId != null) 'classId': classId,
        'studentUid': studentUid,
        'direction': direction,
        'status': result.status.name,
        'checkedAt': Timestamp.fromDate(result.evaluatedAt),
        'deviceLocation': {
          'lat': result.latitude,
          'lng': result.longitude,
          'accuracy': result.accuracyMeters,
        },
        if (result.designatedGeofence != null)
          'designatedLocation': {
            'lat': result.designatedGeofence!.latitude,
            'lng': result.designatedGeofence!.longitude,
            'radiusMeters': result.designatedGeofence!.radiusMeters,
            if (result.designatedGeofence!.campusSlug != null)
              'campusSlug': result.designatedGeofence!.campusSlug,
          },
        'distanceMeters': result.distanceMeters,
        'bandTypeAtTime': result.bandType.name,
        if (result.outsidePolicyApplied != null)
          'outsidePolicyApplied': result.outsidePolicyApplied!.name,
        'outsideMessageShown': result.shouldShowOutsideMessage,
        if (result.outsideMessage != null)
          'outsideMessageText': result.outsideMessage,
        if (incidentRef != null) 'incidentId': incidentRef.id,
        'decision': result.decision.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return CheckStoreResult(
      checkResult: result,
      attendanceId: attendanceRef?.id,
      incidentId: incidentRef?.id,
    );
  } catch (e, stack) {
    print('🔥 Error persisting check-in: $e');
    print(stack);
    rethrow; // Optional: or return a failed CheckStoreResult
  }
}

  Future<DocumentReference<Map<String, dynamic>>> _createIncident({
    required CheckResult result,
    required String studentUid,
    required String sessionId,
    required String direction,
    String? classId,
  }) async {
    try {
      final collection = _db.collection('geofence_incidents');
      return await collection.add({
        'studentUid': studentUid,
        'sessionId': sessionId,
        if (classId != null) 'classId': classId,
        'direction': direction,
        'occurredAt': Timestamp.fromDate(result.evaluatedAt),
        'bandTypeAtTime': result.bandType.name,
        'designatedLocation': {
          'lat': result.designatedGeofence.latitude,
          'lng': result.designatedGeofence.longitude,
          'radiusMeters': result.designatedGeofence.radiusMeters,
          if (result.designatedGeofence.campusSlug != null)
            'campusSlug': result.designatedGeofence.campusSlug,
        },
        'actualLocation': {
          'lat': result.latitude,
          'lng': result.longitude,
          'accuracy': result.accuracyMeters,
        },
        'distanceMeters': result.distanceMeters,
        'outsideMessageShown': result.shouldShowOutsideMessage,
        if (result.outsideMessage != null)
          'outsideMessageText': result.outsideMessage,
        if (result.outsidePolicyApplied != null)
          'outsidePolicyApplied': result.outsidePolicyApplied!.name,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      // Potential Firebase crash causes:
      // - Null references in data fields
      // - Firestore permission denied errors
      // - Network connectivity issues
      print('🔥 Error creating geofence incident: $e');
      print(stack);
      throw Exception('Failed to create geofence incident: $e');
    }
  }
}
