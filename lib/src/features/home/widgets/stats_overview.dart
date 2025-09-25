import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'stats.dart'; // <-- import StatRing

class StatsOverview extends StatelessWidget {
  const StatsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          StatRing(value: 20, label: 'Present', color: Color(0xFF2ECC71)),
          StatRing(value: 5, label: 'Late', color: Color(0xFFF39C12)),
          StatRing(value: 3, label: 'Absent', color: Color(0xFFE74C3C)),
        ],
      ),
    );
  }
}