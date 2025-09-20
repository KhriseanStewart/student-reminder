import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/services/session_manager.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> authStateChanged() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Register a new user and ensure Firestore profile is created
  Future<UserCredential> register({
    required String firstName,
    required String lastName,
    required String courseGroup,
    required String email,
    required String phone,
    required String password,
  }) async {
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
      role: "student", // 👈 default
      createdAt: DateTime.now(),
    );

    // 3️⃣ Save profile to Firestore
    await _db
        .collection("users")
        .doc(uid)
        .set(appUser.toMap(), SetOptions(merge: true));

    // 4️⃣ Save session
    await SessionManager.onLoginSuccess();

    return cred;
  }

  /// Fetch profile by uid
  Future<AppUser?> fetchProfile(String uid) async {
    final snap = await _db.collection("users").doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(uid, snap.data()!);
  }

  /// Login with FirebaseAuth + ensure session is set
  Future<UserCredential> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await SessionManager.onLoginSuccess();
    return cred;
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
    await SessionManager.clear();
  }

  /// Password reset
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

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
}
