import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  final List<Map<String, String>> _mockAchievements = const [
    {
      'title': 'First 5,000 steps',
      'description': 'You hit 5,000 steps in a single day.',
    },
    {
      'title': 'Consistency Starter',
      'description': 'You were active 3 days in a row.',
    },
    {
      'title': 'Workout Logged',
      'description': 'You logged your first workout.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mockAchievements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final achievement = _mockAchievements[index];
          return Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.emoji_events),
              title: Text(
                achievement['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(achievement['description'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}
