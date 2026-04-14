import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DateTime? _memberSince;

  @override
  void initState() {
    super.initState();
    _loadMemberSince();
  }

  Future<void> _loadMemberSince() async {
    final email = AuthService.getCurrentUser();
    if (email == null) return;
    final date = await AuthService.getAccountCreatedAt(email);
    if (mounted) setState(() => _memberSince = date);
  }

  VoidCallback get onLogout => widget.onLogout;

  @override
  Widget build(BuildContext context) {
    final email = AuthService.getCurrentUser();
    final displayName = AuthService.getDisplayName();
    final initial = (displayName != null && displayName.isNotEmpty)
        ? displayName[0].toUpperCase()
        : (email != null && email.isNotEmpty)
        ? email[0].toUpperCase()
        : '?';
    final levelInfo = StorageService.getLevelInfo();
    final unlockedCount = StorageService.getUnlockedAchievements().length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              'Settings',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          // Account section
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF9FA8DA),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: const Text('Account'),
            subtitle: Text(
              _memberSince != null
                  ? '${email ?? ''}  ·  Member since ${DateFormat('MMMM yyyy').format(_memberSince!)}'
                  : email ?? '',
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Lv ${levelInfo.level}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9FA8DA),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${levelInfo.currentXp} XP',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$unlockedCount/7',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4A148C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Achievements',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${StorageService.getCurrentStreak()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF9FA8DA),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Day streak',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out'),
            onTap: () => _confirmLogout(context),
          ),
          const Divider(),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.themeNotifier,
            builder: (context, themeMode, _) {
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                value: themeMode == ThemeMode.dark,
                onChanged: (value) => ThemeService.setDark(value),
              );
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline, color: Color(0xFF9FA8DA)),
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
