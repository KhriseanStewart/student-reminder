import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SessionContext {
  const SessionContext({
    required this.sessionId,
    this.classId,
    required this.scheduledStart,
    this.graceMinutes = 15,
  });

  final String sessionId;
  final String? classId;
  final DateTime scheduledStart;
  final int graceMinutes;

  SessionContext copyWith({
    String? sessionId,
    String? classId,
    DateTime? scheduledStart,
    int? graceMinutes,
  }) {
    return SessionContext(
      sessionId: sessionId ?? this.sessionId,
      classId: classId ?? this.classId,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      graceMinutes: graceMinutes ?? this.graceMinutes,
    );
  }
}

/// Provides the current attendance session context. Override this at the
/// page level when a specific class/session is in scope.
final sessionContextProvider = Provider<SessionContext>((ref) {
  final now = DateTime.now();
  final sessionId = DateFormat('yyyy-MM-dd').format(now);
  final scheduledStart = DateTime(now.year, now.month, now.day, 8, 0);

  return SessionContext(
    sessionId: sessionId,
    scheduledStart: scheduledStart,
    graceMinutes: 15,
  );
});
