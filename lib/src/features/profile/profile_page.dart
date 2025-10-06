import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:students_reminder/src/models/app_user.dart';
import 'package:students_reminder/src/models/attendance_day.dart';
import 'package:students_reminder/src/services/auth_service.dart';
import 'package:students_reminder/src/services/provider.dart';
import 'package:students_reminder/src/models/attendance_stats.dart'
    as stats_model;

import 'edit_profile_page.dart';
import 'widgets/logout_bottom_sheet.dart';

final userUidProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser!.uid;
});

final attendanceStatsProvider = StreamProvider<stats_model.AttendanceStats>((
  ref,
) {
  final repo = ref.watch(attendanceRepoProvider);
  final uid = ref.watch(userUidProvider);
  return repo.watchUserStats(uid);
});

class ProfilePage extends ConsumerWidget {
  final AppUser user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullName = '${user.firstName} ${user.lastName}'.trim();
    final name = fullName.isNotEmpty ? fullName : "Unknown User";

    final repo = ref.watch(attendanceRepoProvider);
    final statsAsync = ref.watch(attendanceStatsProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Header with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C4DFF), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage:
                          (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      backgroundColor: Colors.white24,
                      child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                          ? const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.deepPurpleAccent.withValues(alpha: 0.9),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email.isNotEmpty ? user.email : 'unknown@example.com',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _glassTile(
                  context,
                  icon: Icons.phone,
                  title: "Phone",
                  value: user.phone.isNotEmpty ? user.phone : 'N/A',
                ),
                if ((user.bio ?? '').isNotEmpty)
                  _glassTile(
                    context,
                    icon: Icons.info_outline,
                    title: "Bio",
                    value: user.bio ?? '',
                  ),
                _glassTile(
                  context,
                  icon: Icons.school,
                  title: "Group",
                  value: user.courseGroup.isNotEmpty ? user.courseGroup : 'N/A',
                ),
                const SizedBox(height: 16),
                Text(
                  "Today's Attendance",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                StreamBuilder<AttendanceDay?>(
                  stream: repo.watchToday(),
                  builder: (context, snapshot) {
                    final today = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Status: ${today?.status ?? 'Not marked'}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "Clock In: ${today?.clockInAt?.toLocal().toString().split('.').first ?? 'N/A'}",
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          "Clock Out: ${today?.clockOutAt?.toLocal().toString().split('.').first ?? 'N/A'}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  "Attendance Stats",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                statsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Text(
                    "Error loading stats",
                    style: TextStyle(color: Colors.red),
                  ),
                  data: (stats) => _glassStatsRow(stats),
                ),
                const SizedBox(height: 24),
                _glassButtonTile(
                  context,
                  icon: Icons.edit,
                  label: "Edit Profile",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                ),
                _glassButtonTile(
                  context,
                  icon: Icons.settings,
                  label: "Settings",
                  onTap: () => debugPrint("Settings tapped"),
                ),
                _glassButtonTile(
                  context,
                  icon: Icons.logout,
                  label: "Logout",
                  onTap: () => _onLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purpleAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassStatsRow(stats_model.AttendanceStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statBox("Present", stats.present, Colors.green),
        _statBox("Late", stats.late, Colors.orange),
        _statBox("Absent", stats.absent, Colors.red),
      ],
    );
  }

  Widget _statBox(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _glassButtonTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: Colors.white.withAlpha(13),
        leading: Icon(icon, color: Colors.purpleAccent),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white70,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _onLogout(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LogoutBottomSheet(),
    );

    if (result == true) {
      await AuthService.instance.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
      }
    }
  }
}
