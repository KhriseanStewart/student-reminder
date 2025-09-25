import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:students_reminder/src/services/provider.dart';
import 'package:students_reminder/src/widgets/map_card.dart'; // ✅ Map preview card

class AnalyticsOverview extends ConsumerWidget {
  const AnalyticsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(homeRepoProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Text("No user logged in", style: TextStyle(color: Colors.white)),
      );
    }

    return StreamBuilder<Map<String, int>>(
      stream: repo.watchAttendanceStats(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
          );
        }

        if (snapshot.hasError) {
          return Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(color: Colors.red),
          );
        }

        final stats = snapshot.data ?? {};
        final total = stats.values.fold<int>(0, (sum, v) => sum + v);

        if (stats.isEmpty) {
          return const Text(
            "No attendance records yet.",
            style: TextStyle(color: Colors.white70),
          );
        }

        // Build layout with two columns
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column → Pills
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _statPill(
                    context,
                    "Present",
                    stats["present"] ?? 0,
                    Colors.greenAccent,
                  ),
                  const SizedBox(height: 8),
                  _statPill(
                    context,
                    "Late",
                    stats["late"] ?? 0,
                    Colors.orangeAccent,
                  ),
                  const SizedBox(height: 8),
                  _statPill(
                    context,
                    "Absent",
                    stats["absent"] ?? 0,
                    Colors.redAccent,
                  ),
                  const SizedBox(height: 8),
                  _statPill(context, "Total", total, Colors.blueAccent),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right Column → MapCard
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 195, // match pill stack height
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const MapCard(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Glass-style stat pill with interaction
  Widget _statPill(BuildContext context, String label, int count, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () {
        // 🔹 Later: hook into student list filtering
        debugPrint("Filter tapped: $label");
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: color.withOpacity(0.6), width: 1.3),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
