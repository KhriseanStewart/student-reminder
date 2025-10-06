import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String courseGroup;
  final String email;
  final String phone;
  final String role; // "student" | "admin"
  final String? gender;
  final String? bio;
  final String? photoUrl;
  final DateTime? createdAt;
  final AttendanceStats attendance;

  AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.courseGroup,
    required this.email,
    required this.phone,
    required this.role,
    this.gender,
    this.bio,
    this.photoUrl,
    this.createdAt,
    this.attendance = const AttendanceStats(),
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    }

    return AppUser(
      uid: uid,
      firstName: (data['firstName'] ?? '').toString(),
      lastName: (data['lastName'] ?? '').toString(),
      courseGroup: (data['courseGroup'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      role: (data['role'] ?? 'student').toString(),
      gender: data['gender']?.toString(),
      bio: data['bio']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      createdAt: createdAt,
      attendance: AttendanceStats.fromMap(data['attendance'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'courseGroup': courseGroup,
      'email': email,
      'phone': phone,
      'gender': gender,
      'bio': bio,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'attendance': attendance.toMap(),
    };
  }

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    return uid;
  }

  bool get isAdmin => role.toLowerCase() == "admin";
}

class AttendanceStats {
  final int present;
  final int late;
  final int absent;

  const AttendanceStats({
    this.present = 0,
    this.late = 0,
    this.absent = 0,
  });

  factory AttendanceStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AttendanceStats();
    return AttendanceStats(
      present: (map['present'] ?? 0) as int,
      late: (map['late'] ?? 0) as int,
      absent: (map['absent'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'present': present,
        'late': late,
        'absent': absent,
      };
}