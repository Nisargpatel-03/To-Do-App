import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_app/providers/auth_providers.dart';
import 'package:task_manager_app/providers/theme_provider.dart'; // New theme provider

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
            value: themeMode == ThemeMode.dark,
            onChanged: (isOn) {
              ref.read(themeProvider.notifier).toggleTheme(isOn);
            },
            activeColor: Colors.blueAccent,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[700],
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).iconTheme.color),
            title: Text('Logout', style: TextStyle(color: Theme.of(context).iconTheme.color)),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (!context.mounted) return;
              // Navigating back to login is handled by main.dart's listener
              // Optionally, you can pop all routes if you want a clean stack
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // Add more settings options here (e.g., About, Privacy Policy)
        ],
      ),
    );
  }
}