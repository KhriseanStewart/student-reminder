import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final Widget? action; // 👈 add this

  const EmptyState({super.key, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action!, // 👈 render the action button
          ],
        ],
      ),
    );
  }
}
