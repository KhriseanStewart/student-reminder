import 'dart:async';

import 'package:flutter/material.dart';

class ClockFab extends StatelessWidget {
  const ClockFab({
    super.key,
    required this.isClockedIn,
    required this.isProcessing,
    required this.onClockIn,
    required this.onClockOut,
  });

  final bool isClockedIn;
  final bool isProcessing;
  final Future<void> Function()? onClockIn;
  final Future<void> Function()? onClockOut;

  void _handleTap(Future<void> Function()? callback) {
    if (callback == null) return;
    unawaited(callback());
  }

  @override
  Widget build(BuildContext context) {
    final label = isProcessing
        ? 'Processing…'
        : isClockedIn
        ? 'Clock Out'
        : 'Clock In';
    final icon = isClockedIn ? Icons.logout_rounded : Icons.login_rounded;
    final onTap = isClockedIn ? onClockOut : onClockIn;

    return FloatingActionButton.extended(
      heroTag: 'clock-fab',
      onPressed: isProcessing ? null : () => _handleTap(onTap),
      icon: isProcessing
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}
