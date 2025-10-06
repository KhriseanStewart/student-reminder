import 'package:flutter/material.dart';
import 'package:students_reminder/src/core/utils/distance_utils.dart'
    as distance_utils;
import 'package:students_reminder/src/features/checkin/check_in_service.dart';
import 'package:students_reminder/src/models/check_result.dart';

String _statusLabel(distance_utils.AttStatus status) {
  switch (status) {
    case distance_utils.AttStatus.present:
      return 'Present';
    case distance_utils.AttStatus.late:
      return 'Late';
    case distance_utils.AttStatus.outsideAttempt:
      return 'Outside Area';
  }
}

void showCheckResultFeedback(BuildContext context, CheckStoreResult result) {
  final check = result.checkResult;

  if (check.decision == CheckDecision.block) {
    final message =
        check.outsideMessage ??
        'You are outside the designated area. Please move closer and try again.';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check-in blocked'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  final statusLabel = _statusLabel(check.status);
  final distanceLabel = distance_utils.prettyDistance(check.distanceMeters);
  final timeLabel = TimeOfDay.fromDateTime(check.evaluatedAt).format(context);

  final snackBar = SnackBar(
    content: Text('$statusLabel · $distanceLabel · $timeLabel'),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
