// lib/src/core/utils/distance_utils.dart
import 'dart:math';

/// The three possible attendance outcomes after evaluating geofence + time.
enum AttStatus { present, late, outsideAttempt }

double _degToRad(double degrees) => degrees * pi / 180.0;

/// Calculates the great‑circle distance (in meters) between two points
/// using the Haversine formula.
double haversineDistanceMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadiusMeters = 6371000.0; // mean Earth radius
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);

  final a =
      pow(sin(dLat / 2), 2) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * pow(sin(dLon / 2), 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusMeters * c;
}

/// Formats a distance for display (e.g. “87 m” or “1.24 km”).
String prettyDistance(double meters) {
  if (meters.isNaN || meters.isInfinite) {
    return '—';
  }
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  final km = meters / 1000.0;
  return '${km.toStringAsFixed(2)} km';
}

/// Resolves the attendance status using geofence distance + start time.
AttStatus resolveStatus({
  required DateTime now,
  required DateTime classStart,
  required int graceMinutes,
  required double distanceMeters,
  required double radiusMeters,
}) {
  final day = now.weekday;

  // Enforce Stony Hill restriction on Wednesdays and Thursdays
  final stonyHillDays = [DateTime.wednesday, DateTime.thursday];
  if (stonyHillDays.contains(day) && distanceMeters > radiusMeters) {
    return AttStatus.outsideAttempt;
  }

  final cutoff = classStart.add(Duration(minutes: graceMinutes));
  return now.isAfter(cutoff) ? AttStatus.late : AttStatus.present;
}
