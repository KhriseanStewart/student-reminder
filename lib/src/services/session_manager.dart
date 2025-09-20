import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // 🔑 Keys
  static const _keyLogin = 'loginState';
  static const _keyIntroSeen = 'introSeen';

  static const maxAge = Duration(minutes: 35);

  // --- LOGIN SESSION ---
  /// Save login timestamp
  static Future<void> onLoginSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLogin, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear session + (optionally) intro flag
  static Future<void> clear({bool resetIntro = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLogin);
    if (resetIntro) {
      await prefs.remove(_keyIntroSeen); // only if you want intro reset
    }
  }

  /// Has login session expired?
  static Future<bool> isExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_keyLogin);
    if (ts == null) return false;
    final loginTime = DateTime.fromMillisecondsSinceEpoch(ts); // ✅ FIXED
    return DateTime.now().difference(loginTime) > maxAge;
  }

  // --- INTRO TRACKING ---
  /// Mark intro as seen
  static Future<void> setIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIntroSeen, true);
  }

  /// Check if intro already seen
  static Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIntroSeen) ?? false;
  }
}
