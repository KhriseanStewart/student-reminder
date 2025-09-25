    import 'package:flutter/material.dart';

    class ClockPill extends StatelessWidget {
      final bool isClockedIn;
      final VoidCallback? onClockIn;
      final VoidCallback? onClockOut;

      const ClockPill({
        super.key,
        required this.isClockedIn,
        required this.onClockIn,
        required this.onClockOut,
      });

      bool _isWithinWorkingHours() {
        final now = DateTime.now();
        return now.hour >= 8 && now.hour < 16; // ⏰ between 8am and 4pm
      }

      @override
      Widget build(BuildContext context) {
        final canUse = _isWithinWorkingHours();

        final label = isClockedIn ? "Clock Out" : "Clock In";
        final color = isClockedIn ? Colors.redAccent : Colors.deepPurpleAccent;
        final onTap = canUse
            ? (isClockedIn ? onClockOut : onClockIn)
            : null; // disabled outside hours

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: canUse ? color : Colors.grey[700], // 🔹 Purple / Red / Grey
              borderRadius: BorderRadius.circular(30), // pill shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              canUse ? label : "Unavailable",
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
