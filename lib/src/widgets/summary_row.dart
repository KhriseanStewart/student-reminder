import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SummaryRow extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const SummaryRow({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    // ✅ Count statuses
    final present = docs.where((d) => d['status'] == 'present').length;
    final late = docs.where((d) => d['status'] == 'late').length;
    final absent = docs.where((d) => d['status'] == 'absent').length;
    final droppedOut = docs.where((d) => d['status'] == 'droppedOut').length;

    return Column(
      children: [
        Row(
          children: [
            summaryCard(
              label: "Present",
              count: present,
              borderColor: Colors.greenAccent,
              icon: Icons.check_circle,
              bgColor: Colors.lightBlueAccent,
            ),
            summaryCard(
              label: "Late",
              count: late,
              borderColor: Colors.orangeAccent,
              icon: Icons.access_time,
            ),
          ],
        ),
        Row(
          children: [
            summaryCard(
              label: "Absent",
              count: absent,
              borderColor: Colors.redAccent,
              bgColor: Colors.lightBlueAccent,
              icon: Icons.cancel,
            ),
            summaryCard(
              label: "Dropped Out",
              count: droppedOut,
              borderColor: Colors.redAccent,
              icon: Icons.remove_circle,
            ),
          ],
        ),
      ],
    );
  }

  Widget summaryCard({
    required String label,
    required int count,
    required Color borderColor,
    required IconData icon,
    Color? bgColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: borderColor, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
