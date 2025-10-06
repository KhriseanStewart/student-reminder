// lib/src/services/geofence_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/core/utils/distance_utils.dart';
import 'package:students_reminder/src/models/check_result.dart';
import 'package:students_reminder/src/models/geofence_profile.dart';

class GeofenceService {
  GeofenceService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<OrgDefaults> loadOrgDefaults() async {
    try {
      final doc = await _db.collection('org_config').doc('defaults').get();
      if (!doc.exists) {
        return OrgDefaults.fallback();
      }
      return OrgDefaults.fromMap(doc.data() ?? {});
    } catch (_) {
      return OrgDefaults.fallback();
    }
  }

  Future<CampusLocation?> loadCampusBySlug(String slug) async {
    try {
      final doc = await _db.collection('campus_locations').doc(slug).get();
      if (!doc.exists) return null;
      return CampusLocation.fromMap(slug, doc.data());
    } catch (_) {
      return null;
    }
  }

  Future<GeofenceProfile?> loadProfile(String uid, int dow) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('geofence_profiles')
          .doc(dow.toString())
          .get();
      if (!doc.exists) {
        return null;
      }
      return GeofenceProfile.fromMap(doc.data() ?? {});
    } catch (_) {
      return null;
    }
  }

  Future<GeofenceUserSettings?> loadUserSettings(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return GeofenceUserSettings.fromMap(uid, doc.data());
    } catch (_) {
      return null;
    }
  }

  Future<EffectiveGeofence> resolveEffectiveGeofence({
    required GeofenceUserSettings user,
    required int dow,
    required OrgDefaults defaults,
  }) async {
    final profile = await loadProfile(user.uid, dow);
    final bandType = profile?.bandTypeOverride ?? user.bandType;
    final outsidePolicy = bandType == BandType.fixed
        ? profile?.outsidePolicy ?? OutsidePolicy.block
        : null;
    final outsideMessage =
        profile?.outsideMessageText ?? user.effectiveOutsideMessage;

    final checkIn = await _resolveSlot(
      slot: GeofenceSlot.checkIn,
      dow: dow,
      profile: profile,
      defaults: defaults,
    );
    final checkOut = await _resolveSlot(
      slot: GeofenceSlot.checkOut,
      dow: dow,
      profile: profile,
      defaults: defaults,
    );

    return EffectiveGeofence(
      checkIn: checkIn,
      checkOut: checkOut,
      bandType: bandType,
      outsidePolicy: outsidePolicy,
      outsideMessageText: outsideMessage,
    );
  }

  double distanceToDesignated({
    required double latitude,
    required double longitude,
    required Geofence geofence,
  }) {
    return haversineDistanceMeters(
      lat1: latitude,
      lon1: longitude,
      lat2: geofence.latitude,
      lon2: geofence.longitude,
    );
  }

  Future<CheckResult> evaluateCheckInOut({
    required EffectiveGeofence effectiveGeofence,
    required bool isCheckIn,
    required DateTime now,
    required DateTime scheduledStart,
    required int graceMinutes,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) async {
    final designated = isCheckIn
        ? effectiveGeofence.checkIn
        : effectiveGeofence.checkOut;

    final distance = distanceToDesignated(
      latitude: latitude,
      longitude: longitude,
      geofence: designated,
    );

    final bandType = effectiveGeofence.bandType;
    final cutoff = scheduledStart.add(Duration(minutes: graceMinutes));

    final timeStatus = now.isAfter(cutoff) ? AttStatus.late : AttStatus.present;

    var status = resolveStatus(
      now: now,
      classStart: scheduledStart,
      graceMinutes: graceMinutes,
      distanceMeters: distance,
      radiusMeters: designated.radiusMeters,
    );

    var decision = CheckDecision.allow;
    var requiresIncident = false;
    var shouldShowOutsideMessage = false;
    OutsidePolicy? appliedPolicy = effectiveGeofence.outsidePolicy;
    String? outsideMessage;

    if (bandType == BandType.floating) {
      status = timeStatus;
      decision = CheckDecision.allow;
      requiresIncident = false;
      appliedPolicy = null;
    } else if (status == AttStatus.outsideAttempt) {
      requiresIncident = true;
      shouldShowOutsideMessage =
          (effectiveGeofence.outsideMessageText?.trim().isNotEmpty ?? false);
      outsideMessage = shouldShowOutsideMessage
          ? effectiveGeofence.outsideMessageText
          : null;

      if (effectiveGeofence.outsidePolicy == OutsidePolicy.allowAndFlag) {
        decision = CheckDecision.allow;
      } else {
        decision = CheckDecision.block;
      }
    } else {
      decision = CheckDecision.allow;
    }

    return CheckResult(
      decision: decision,
      status: status,
      distanceMeters: distance,
      accuracyMeters: accuracyMeters,
      accuracyExceedsRadius: accuracyMeters > designated.radiusMeters,
      designatedGeofence: designated,
      bandType: bandType,
      requiresIncident: requiresIncident,
      shouldShowOutsideMessage: shouldShowOutsideMessage,
      outsideMessage: outsideMessage,
      outsidePolicyApplied: appliedPolicy,
      evaluatedAt: now,
      latitude: latitude,
      longitude: longitude,
      isCheckIn: isCheckIn,
    );
  }

  Future<Geofence> _resolveSlot({
    required GeofenceSlot slot,
    required int dow,
    required GeofenceProfile? profile,
    required OrgDefaults defaults,
  }) async {
    final override = profile?.slot(slot);
    if (override != null) {
      return override;
    }

    final fallbackSlug = defaults.campusSlugForDow(dow);
    final campus = await loadCampusBySlug(fallbackSlug);

    final latitude = campus?.latitude ?? 0.0;
    final longitude = campus?.longitude ?? 0.0;
    final radius = campus?.defaultRadiusMeters ?? defaults.defaultRadiusMeters;

    return Geofence(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radius,
      campusSlug: campus?.slug ?? fallbackSlug,
    );
  }
}
