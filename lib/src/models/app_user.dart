import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String firstName;
  final String lastName;
  final String courseGroup; // e.g. "web" | "mobile"
  final String email;
  final String phone;
  final String? gender;
  final String? bio;
  final String? photoUrl;
  final DateTime? createdAt;
  final String role; // 🔑 "student" | "admin"

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
  });

  /// Factory to safely create [AppUser] from Firestore data
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
      role: (data['role'] ?? 'student').toString(), // ✅ default student
      gender: data['gender']?.toString(),
      bio: data['bio']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      createdAt: createdAt,
    );
  }

  /// Convert [AppUser] to Firestore map
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
    };
  }

  /// Display name with fallback to email or UID
  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    return uid; // fallback
  }

  /// 🔑 Quick role check
  bool get isAdmin => role.toLowerCase() == "admin";
}
