import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String displayName;
  final String photoUrl;
  final Widget searchBar;
  final Widget quickActions;

  const HomeHeader({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.searchBar,
    required this.quickActions,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "🌅 Good Morning";
    if (hour < 18) return "🌞 Good Afternoon";
    return "🌙 Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0D47A1), // Darker blue for dark mode
                    const Color(0xFF1976D2), // Lighter blue
                  ]
                : [
                    const Color(0xFFE3F2FD), // Light blue for light mode
                    const Color(0xFF90CAF9),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Greeting + Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar + Greeting
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(photoUrl),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Icons
                Row(
                  children: const [
                    Icon(Icons.notifications_none_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Icon(Icons.bookmark_border_rounded, color: Colors.white),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),
            searchBar,
            const SizedBox(height: 16),
            quickActions,
          ],
        ),
      ),
    );
  }
}
