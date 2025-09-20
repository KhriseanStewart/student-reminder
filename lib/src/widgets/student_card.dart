import 'package:flutter/material.dart';
import 'package:students_reminder/src/models/app_user.dart';

class StudentCard extends StatelessWidget {
  final AppUser student;
  final VoidCallback? onTap;

  const StudentCard({super.key, required this.student, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurpleAccent, width: 1.2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.deepPurpleAccent,
              backgroundImage: student.photoUrl != null
                  ? NetworkImage(student.photoUrl!)
                  : null,
              child: student.photoUrl == null
                  ? Text(
                      student.firstName.isNotEmpty
                          ? student.firstName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.courseGroup,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
