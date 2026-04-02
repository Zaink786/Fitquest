import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final email = AuthService.getCurrentUser();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Account section
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: const Text('Account'),
            subtitle: Text(email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out'),
            onTap: () => _confirmLogout(context),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.blue),
            title: Text('About'),
            subtitle: Text('FitQuest v1.0.0'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.orange),
            title: const Text('Data Management'),
            subtitle: const Text('View and manage your stored data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showDataInfo(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Remove all workouts, points, and streaks'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data?'),
                  content: const Text(
                    'This will permanently delete all your workouts, points, and streaks. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await StorageService.clearAllData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      onLogout();
    }
  }

  void _showDataInfo(BuildContext context) {
    final workouts = StorageService.getAllWorkouts();
    final points = StorageService.getTotalPoints();
    final streak = StorageService.getCurrentStreak();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Workouts: ${workouts.length}'),
            const SizedBox(height: 8),
            Text('Total Points: $points'),
            const SizedBox(height: 8),
            Text('Current Streak: $streak days'),
            const SizedBox(height: 16),
            const Text(
              'All data is stored locally on your device.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
