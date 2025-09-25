import 'package:flutter/material.dart';
import 'package:students_reminder/src/models/app_user.dart';

class StudentCard extends StatelessWidget {
  final AppUser student;
  final VoidCallback? onTap;
  final VoidCallback? onSettingsTap; // 👈 optional settings handler

  const StudentCard({
    super.key,
    required this.student,
    this.onTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0, // 🔹 Flat Material 3 look
      color: cs.surfaceVariant.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 👤 Avatar (circle, with photo or fallback letter)
              CircleAvatar(
                radius: 26,
                backgroundColor: cs.primary.withOpacity(0.8),
                backgroundImage:
                    student.photoUrl != null && student.photoUrl!.isNotEmpty
                    ? NetworkImage(student.photoUrl!)
                    : null,
                child: (student.photoUrl == null || student.photoUrl!.isEmpty)
                    ? Text(
                        student.firstName.isNotEmpty
                            ? student.firstName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 14),

              // 📋 Name + course group
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.courseGroup,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // ⚙️ Settings icon placeholder
              if (onSettingsTap != null)
                IconButton(
                  icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                  onPressed: onSettingsTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
