// lib/src/features/profile/widgets/info_card.dart
import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final IconData? icon; // optional
  final Color iconColor; // customizable
  final String label;
  final Widget value; // ✅ flexible: text, row, anything
  final VoidCallback? onTap; // optional tap handler

  const InfoCard({
    super.key,
    this.icon,
    this.iconColor = Colors.purpleAccent,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // only clickable if provided
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  value, // ✅ dynamic widget instead of just string
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
