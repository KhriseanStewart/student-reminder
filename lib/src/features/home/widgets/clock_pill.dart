import 'dart:async';

import 'package:flutter/material.dart';

class ClockPill extends StatelessWidget {
  const ClockPill({
    super.key,
    required this.isClockedIn,
    required this.isLoading,
    this.onClockIn,
    this.onClockOut,
  });

  final bool isClockedIn;
  final bool isLoading;
  final Future<void> Function()? onClockIn;
  final Future<void> Function()? onClockOut;

  bool _isWithinWorkingHours() {
    final now = DateTime.now();
    return now.hour >= 8 && now.hour < 16; // ⏰ between 8am and 4pm
  }

  void _handleTap(Future<void> Function()? callback) {
    if (callback == null) return;
    unawaited(callback());
  }

  @override
  Widget build(BuildContext context) {
    final canUse = _isWithinWorkingHours() && !isLoading;

    final label = isLoading
        ? 'Processing…'
        : isClockedIn
        ? 'Clock Out'
        : 'Clock In';
    final color = isClockedIn ? Colors.redAccent : Colors.deepPurpleAccent;
    final action = isClockedIn ? onClockOut : onClockIn;

    return GestureDetector(
      onTap: canUse ? () => _handleTap(action) : null,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: canUse ? color : Colors.grey[700],
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                canUse ? label : 'Unavailable',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
