import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/services/session_manager.dart';

/// 🔹 Custom Auth Exception for clean, friendly errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanged() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Register a new user and ensure Firestore profile is created
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String courseGroup,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // 1️⃣ Create FirebaseAuth user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // 2️⃣ Build AppUser profile
      final appUser = AppUser(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        courseGroup: courseGroup,
        email: email,
        phone: phone,
        role: "student", // default
        createdAt: DateTime.now(),
      );

      // 3️⃣ Save profile to Firestore
      await _db
          .collection("users")
          .doc(uid)
          .set(appUser.toMap(), SetOptions(merge: true));

      // 4️⃣ Save session
      await SessionManager.onLoginSuccess();

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } on PlatformException catch (_) {
      throw AuthException("Registration failed due to a platform error.");
    } catch (_) {
      throw AuthException("An unexpected error occurred. Please try again.");
    }
  }

  /// Fetch profile by uid
  Future<AppUser?> fetchProfile(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  /// Login with FirebaseAuth + safe error handling
  Future<AppUser> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await SessionManager.onLoginSuccess();

      final uid = cred.user!.uid;
      final appUser = await fetchProfile(uid);
      if (appUser == null) {
        throw AuthException("Profile not found.");
      }

      return appUser; // ✅ return AppUser, not UserCredential
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } on PlatformException catch (_) {
      throw AuthException("Login failed due to a platform error.");
    } catch (_) {
      throw AuthException("An unexpected error occurred. Please try again.");
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
    await SessionManager.clear();
  }

  /// Password reset
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } catch (_) {
      throw AuthException("Failed to send password reset email. Try again.");
    }
  }

  /// Check user role
  Future<String?> getUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection("users").doc(uid).get();
    return snap.data()?['role'] as String?;
  }

  Future<bool> isAdmin(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return false;
    final role = snap.data()?['role'] as String?;
    return role == "admin";
  }

  /// 🔹 Map Firebase error codes into friendly messages
  String _mapFirebaseError(String code) {
    switch (code) {
      // Login / Register
      case 'invalid-email':
        return "Please enter a valid email address.";
      case 'user-not-found':
        return "No account found with this email.";
      case 'wrong-password':
        return "Incorrect password. Try again.";
      case 'user-disabled':
        return "This account has been disabled.";
      case 'invalid-credential':
        return "Invalid credentials. Please check your email and password.";
      // Register specific
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'weak-password':
        return "Password must be at least 6 characters long.";
      default:
        return "Something went wrong. Please try again.";
    }
  }
}
