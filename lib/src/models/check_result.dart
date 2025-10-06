// lib/src/models/check_result.dart
import 'package:students_reminder/src/core/utils/distance_utils.dart';
import 'package:students_reminder/src/models/geofence_profile.dart';

enum CheckDecision { allow, block }

class CheckResult {
  const CheckResult({
    required this.decision,
    required this.status,
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.accuracyExceedsRadius,
    required this.designatedGeofence,
    required this.bandType,
    required this.requiresIncident,
    required this.shouldShowOutsideMessage,
    required this.isCheckIn,
    this.outsideMessage,
    this.outsidePolicyApplied,
    required this.evaluatedAt,
    required this.latitude,
    required this.longitude,
  });

  final CheckDecision decision;
  final AttStatus status;
  final double distanceMeters;
  final double accuracyMeters;
  final bool accuracyExceedsRadius;
  final Geofence designatedGeofence;
  final BandType bandType;
  final bool requiresIncident;
  final bool shouldShowOutsideMessage;
  final bool isCheckIn;
  final String? outsideMessage;
  final OutsidePolicy? outsidePolicyApplied;
  final DateTime evaluatedAt;
  final double latitude;
  final double longitude;

  bool get isAllowed => decision == CheckDecision.allow;
  bool get isOutside => status == AttStatus.outsideAttempt;
}
