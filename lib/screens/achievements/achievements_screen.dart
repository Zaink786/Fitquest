import 'package:flutter/material.dart';
import '../../models/achievement_model.dart';
import '../../services/storage_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _achievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  void _loadAchievements() {
    final unlockedIds = StorageService.getUnlockedAchievements();
    
    setState(() {
      _achievements = Achievements.allAchievements.map((achievement) {
        final isUnlocked = unlockedIds.contains(achievement.id);
        return achievement.copyWith(isUnlocked: isUnlocked);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$unlockedCount/${_achievements.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadAchievements();
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _achievements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final achievement = _achievements[index];
            return Card(
              elevation: achievement.isUnlocked ? 3 : 1,
              color: achievement.isUnlocked ? null : Colors.grey[100],
              child: ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: achievement.isUnlocked 
                        ? Colors.amber[100] 
                        : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: TextStyle(
                        fontSize: 24,
                        opacity: achievement.isUnlocked ? 1.0 : 0.4,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: achievement.isUnlocked ? Colors.black : Colors.grey[600],
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        color: achievement.isUnlocked ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                    if (achievement.targetValue != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Target: ${achievement.targetValue}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: achievement.isUnlocked
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 32,
                      )
                    : Icon(
                        Icons.lock_outline,
                        color: Colors.grey[400],
                        size: 32,
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
