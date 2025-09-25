// lib/src/features/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:students_reminder/src/services/auth_service.dart';

// widgets
import 'widgets/header.dart';
import 'widgets/info_card.dart';
import 'widgets/stats_card.dart';
import 'widgets/profile_action_tile.dart';
import 'widgets/logout_bottom_sheet.dart'; // ✅ new bottom sheet

// screens
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _onLogout(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // let widget handle bg
      builder: (ctx) => const LogoutBottomSheet(),
    );

    if (result == true) {
      await AuthService.instance.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data() ?? {};
        final name = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
            .trim();
        final phone = data['phone'] ?? "";
        final bio = data['bio'] ?? "";
        final group = data['courseGroup'] ?? "";
        final photoUrl = data['photoUrl'];

        final present = (data['attendance']?['present'] ?? 0) as int;
        final late = (data['attendance']?['late'] ?? 0) as int;
        final absent = (data['attendance']?['absent'] ?? 0) as int;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              // 🔹 Header
              ProfileHeader(
                name: name.isNotEmpty ? name : "Unknown User",
                email: user.email ?? "No email",
                photoUrl: photoUrl,
                onChangePhoto: () {
                  // handled in header or EditProfilePage
                },
              ),

              // 🔹 Main content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle("Information"),
                    if (phone.isNotEmpty)
                      InfoCard(
                        icon: Icons.phone,
                        label: "Phone",
                        value: Text(
                          phone,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    if (bio.isNotEmpty)
                      InfoCard(
                        icon: Icons.info_outline,
                        label: "Bio",
                        value: Text(
                          bio,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    if (group.isNotEmpty)
                      InfoCard(
                        icon: Icons.school,
                        label: "Group",
                        value: Text(
                          group,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    const SizedBox(height: 20),

                    _sectionTitle("Attendance Stats"),
                    StatsCard(present: present, late: late, absent: absent),
                    const SizedBox(height: 24),

                    _sectionTitle("Actions"),
                    ProfileActionTile(
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
                    ProfileActionTile(
                      icon: Icons.settings,
                      label: "Settings",
                      onTap: () {
                        debugPrint("Settings tapped");
                        // ✅ Could also slide up a bottom sheet here later
                      },
                    ),
                    ProfileActionTile(
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
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
