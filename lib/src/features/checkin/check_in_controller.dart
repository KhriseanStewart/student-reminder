import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:students_reminder/src/features/checkin/check_in_service.dart';
import 'package:students_reminder/src/models/geofence_profile.dart';
import 'package:students_reminder/src/providers/geofence_providers.dart';
import 'package:students_reminder/src/services/location_service.dart';

class CheckInException implements Exception {
  CheckInException(this.message);
  final String message;

  @override
  String toString() => message;
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final checkInControllerProvider =
    AutoDisposeAsyncNotifierProvider<CheckInController, CheckStoreResult?>(
      CheckInController.new,
    );

class CheckInController extends AutoDisposeAsyncNotifier<CheckStoreResult?> {
  @override
  FutureOr<CheckStoreResult?> build() => null;

  Future<CheckStoreResult> attemptCheck({
    required bool isCheckIn,
    required String sessionId,
    String? classId,
    required DateTime scheduledStart,
    int graceMinutes = 0,
    DateTime? now,
    Position? positionOverride,
    EffectiveGeofence? effectiveOverride,
  }) async {
    state = const AsyncValue.loading();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw CheckInException('No authenticated user found.');
      }

      final locationService = ref.read(locationServiceProvider);
      final hasPermission = await locationService.ensurePermission();
      if (!hasPermission) {
        throw CheckInException('Location permission is required to proceed.');
      }

      final position =
          positionOverride ?? await locationService.getCurrentPosition();
      final timestamp = now ?? DateTime.now();

      final effectiveGeofence =
          effectiveOverride ??
          await ref.read(effectiveGeofenceProvider(uid).future);

      if (effectiveGeofence == null) {
        throw CheckInException(
          'No geofence profile is configured for today. Please contact your administrator.',
        );
      }

      final geofenceService = ref.read(geofenceServiceProvider);
      final evaluation = await geofenceService.evaluateCheckInOut(
        effectiveGeofence: effectiveGeofence,
        isCheckIn: isCheckIn,
        now: timestamp,
        scheduledStart: scheduledStart,
        graceMinutes: graceMinutes,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );

      final persistence = ref.read(checkInPersistenceProvider);
      final stored = await persistence.persist(
        result: evaluation,
        studentUid: uid,
        sessionId: sessionId,
        classId: classId,
      );

      state = AsyncValue.data(stored);
      return stored;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }

  Future<CheckStoreResult> checkIn({
    required String sessionId,
    String? classId,
    required DateTime scheduledStart,
    int graceMinutes = 0,
    DateTime? now,
    Position? positionOverride,
    EffectiveGeofence? effectiveOverride,
  }) {
    return attemptCheck(
      isCheckIn: true,
      sessionId: sessionId,
      classId: classId,
      scheduledStart: scheduledStart,
      graceMinutes: graceMinutes,
      now: now,
      positionOverride: positionOverride,
      effectiveOverride: effectiveOverride,
    );
  }

  Future<CheckStoreResult> checkOut({
    required String sessionId,
    String? classId,
    required DateTime scheduledStart,
    int graceMinutes = 0,
    DateTime? now,
    Position? positionOverride,
    EffectiveGeofence? effectiveOverride,
  }) {
    return attemptCheck(
      isCheckIn: false,
      sessionId: sessionId,
      classId: classId,
      scheduledStart: scheduledStart,
      graceMinutes: graceMinutes,
      now: now,
      positionOverride: positionOverride,
      effectiveOverride: effectiveOverride,
    );
  }
}
