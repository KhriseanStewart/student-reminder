// lib/src/providers/geofence_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:students_reminder/src/models/check_result.dart';
import 'package:students_reminder/src/models/geofence_profile.dart';
import 'package:students_reminder/src/services/geofence_service.dart';

final geofenceServiceProvider = Provider<GeofenceService>(
  (ref) => GeofenceService(),
);

final orgDefaultsProvider = FutureProvider<OrgDefaults>((ref) async {
  final service = ref.read(geofenceServiceProvider);
  return service.loadOrgDefaults();
});

final effectiveGeofenceProvider =
    FutureProvider.family<EffectiveGeofence?, String>((ref, uid) async {
      final service = ref.read(geofenceServiceProvider);
      final defaults = await ref.watch(orgDefaultsProvider.future);
      final user = await service.loadUserSettings(uid);
      if (user == null) return null;

      final now = DateTime.now();
      final dow = now.weekday % 7;
      return service.resolveEffectiveGeofence(
        user: user,
        dow: dow,
        defaults: defaults,
      );
    });

class CheckEvaluationParams {
  const CheckEvaluationParams({
    required this.uid,
    required this.isCheckIn,
    required this.latitude,
    required this.longitude,
    required this.now,
    required this.accuracyMeters,
    required this.scheduledStart,
    this.graceMinutes = 0,
  });

  final String uid;
  final bool isCheckIn;
  final double latitude;
  final double longitude;
  final DateTime now;
  final double accuracyMeters;
  final DateTime scheduledStart;
  final int graceMinutes;
}

final checkResultProvider =
    FutureProvider.family<CheckResult?, CheckEvaluationParams>((
      ref,
      params,
    ) async {
      final effective = await ref.watch(
        effectiveGeofenceProvider(params.uid).future,
      );
      if (effective == null) return null;

      final service = ref.read(geofenceServiceProvider);
      return service.evaluateCheckInOut(
        effectiveGeofence: effective,
        isCheckIn: params.isCheckIn,
        now: params.now,
        scheduledStart: params.scheduledStart,
        graceMinutes: params.graceMinutes,
        latitude: params.latitude,
        longitude: params.longitude,
        accuracyMeters: params.accuracyMeters,
      );
    });
