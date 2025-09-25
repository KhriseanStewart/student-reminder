import 'dart:ui';
import 'package:flutter/material.dart';

class SearchBarX extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchTap;
  final String hint;
  final TextEditingController? controller;

  const SearchBarX({
    super.key,
    this.onChanged,
    this.onSearchTap,
    this.hint = 'Search students...',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Sizes tuned to match pill + floating circle
    const double barHeight = 52;
    const double circleSize = 48;
    const double circleInset = 4; // spacing before circle
    const double circleOver = -10; // circle floats a bit outside

    return SizedBox(
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 👇 BAR
          Positioned.fill(
            right: circleSize + circleInset,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(barHeight / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    color: Colors.black.withOpacity(0.35),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.10),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: const TextStyle(color: Colors.white60),
                      contentPadding: const EdgeInsets.only(right: 8),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 👇 FLOATING SEARCH ICON
          Positioned(
            right: circleOver,
            top: (barHeight - circleSize) / 2,
            child: Material(
              elevation: 4, // subtle elevation
              shape: const CircleBorder(),
              shadowColor: Colors.black45,
              child: InkWell(
                onTap: onSearchTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.primary.withOpacity(0.85)],
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
