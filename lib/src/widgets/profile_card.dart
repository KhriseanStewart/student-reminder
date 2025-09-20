import 'package:flutter/material.dart';
import 'package:students_reminder/src/models/app_user.dart';

class ProfileCard extends StatelessWidget {
  final AppUser student;

  const ProfileCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: student.photoUrl != null
              ? NetworkImage(student.photoUrl!)
              : null,
          backgroundColor: Colors.deepPurpleAccent,
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
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              student.courseGroup,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}