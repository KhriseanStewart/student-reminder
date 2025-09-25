import 'dart:ui';
import 'package:flutter/material.dart';

/// Variants for QuickAction pill buttons
enum QuickActionVariant { filled, outlined, tonal, disabled, glass }

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final QuickActionVariant variant;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.variant = QuickActionVariant.filled, // default = primary filled
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Default values
    Color bgColor = scheme.surfaceVariant;
    Color borderColor = Colors.transparent;
    Color textColor = scheme.onSurface;
    Color iconColor = scheme.onSurface;
    List<BoxShadow> shadows = [];

    switch (variant) {
      case QuickActionVariant.filled:
        bgColor = scheme.primary;
        textColor = scheme.onPrimary;
        iconColor = scheme.onPrimary;
        shadows = [
          BoxShadow(
            color: scheme.primary.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ];
        break;

      case QuickActionVariant.outlined:
        bgColor = Colors.transparent;
        borderColor = scheme.primary.withOpacity(0.6);
        textColor = scheme.primary;
        iconColor = scheme.primary;
        break;

      case QuickActionVariant.tonal:
        bgColor = scheme.secondaryContainer;
        textColor = scheme.onSecondaryContainer;
        iconColor = scheme.onSecondaryContainer;
        break;

      case QuickActionVariant.disabled:
        bgColor = scheme.surfaceVariant.withOpacity(0.4);
        textColor = scheme.onSurface.withOpacity(0.4);
        iconColor = scheme.onSurface.withOpacity(0.4);
        break;

      case QuickActionVariant.glass:
        // Transparent glass pill
        bgColor = Colors.white.withOpacity(0.12);
        borderColor = Colors.white.withOpacity(0.24);
        textColor = Colors.white;
        iconColor = Colors.white;
        break;
    }

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: variant == QuickActionVariant.disabled ? null : onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: variant == QuickActionVariant.glass ? null : bgColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: shadows,
          ),
          child: variant == QuickActionVariant.glass
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: child,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}
