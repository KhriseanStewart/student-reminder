import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// 🔹 Watch a single user profile in real-time
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  /// 🔹 Return filtered list of students by course group
  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserByCourseGroup(
    String course,
  ) {
    // Example: course = "web" or "mobile"
    debugPrint('***>> doc value: ${_db.collection('users').snapshots()}');
    return _db
        .collection('users')
        .where('courseGroup', isEqualTo: course)
        .orderBy('lastName')
        .snapshots();
  }

  /// 🔹 Update a user’s profile with optional fields
  Future<void> updateMyProfile(
    String uid, {
    String? gender,
    String? phone,
    String? bio,
  }) async {
    final data = <String, dynamic>{};
    if (gender != null) data['gender'] = gender;
    if (phone != null) data['phone'] = phone;
    if (bio != null) data['bio'] = bio;

    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    }
  }

  /// 🔹 Upload profile photo and update Firestore user document
  Future<String?> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    String? fileName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _resolveExtension(fileName);
    final ref = _storage.ref().child('avatars/$uid/$timestamp$extension');

    // Upload the raw bytes (works across web/mobile/desktop)
    await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentType(extension)),
    );

    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).set({
      'photoUrl': url,
    }, SetOptions(merge: true));
    return url;
  }

  String _resolveExtension(String? fileName) {
    if (fileName != null) {
      final dotIndex = fileName.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < fileName.length - 1) {
        return fileName.substring(dotIndex).toLowerCase();
      }
    }
    return '.jpg';
  }

  /// 🔹 Admin: watch attendance across all users
  /// Supports optional `startDate` and `endDate` filters.
  Stream<QuerySnapshot<Map<String, dynamic>>> adminDoc({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collectionGroup("attendance");

      // ✅ Apply date filters if provided
      if (startDate != null) {
        query = query.where(
          "date",
          isGreaterThanOrEqualTo:
              "${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
        );
      }

      if (endDate != null) {
        query = query.where(
          "date",
          isLessThanOrEqualTo:
              "${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
        );
      }

      // Always order newest first
      query = query.orderBy("date", descending: true);

      return query.snapshots();
    } catch (e, st) {
      debugPrint("❌ Error loading adminDoc: $e\n$st");
      return const Stream.empty();
    }
  }

  /// 🔹 Resolve MIME type based on file extension
  String _contentType(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}
