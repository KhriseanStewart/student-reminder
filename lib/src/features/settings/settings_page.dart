// lib/src/features/settings/settings_page.dart
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text(
              "Dark Mode",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Enable/disable dark theme",
              style: TextStyle(color: Colors.white70),
            ),
            value: true, // TODO: link to theme provider
            onChanged: (val) {
              debugPrint("Dark Mode switched: $val");
            },
          ),
          const Divider(color: Colors.white24),

          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.white),
            title: const Text(
              "Notifications",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              debugPrint("Notifications tapped");
            },
          ),
          const Divider(color: Colors.white24),

          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.white),
            title: const Text(
              "Privacy & Security",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              debugPrint("Privacy tapped");
            },
          ),
          const Divider(color: Colors.white24),

          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text("About", style: TextStyle(color: Colors.white)),
            onTap: () {
              debugPrint("About tapped");
            },
          ),
        ],
      ),
    );
  }
}
