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
    final total = docs.length;

    Widget summaryCard({
      required String label,
      required int count,
      required Color numberColor,
    }) {
      return Expanded(
        child: Column(
          children: [
            // Count number with background
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: numberColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: numberColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                count.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: numberColor,
                ),
              ),
            ),
            SizedBox(height: 8),
            // Label
            Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        summaryCard(
          label: "Total",
          count: total,
          numberColor: Colors.blue.shade300,
        ),
        summaryCard(
          label: "Present",
          count: present,
          numberColor: Colors.green.shade300,
        ),
        summaryCard(
          label: 'Late',
          count: late,
          numberColor: Colors.orange.shade300,
        ),
        summaryCard(
          label: 'Absent',
          count: absent,
          numberColor: Colors.red.shade300,
        ),
      ],
    );
  }
}
