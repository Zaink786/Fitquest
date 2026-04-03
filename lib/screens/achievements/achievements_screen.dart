import 'package:flutter/material.dart';
import '../../models/achievement_model.dart';
import '../../services/storage_service.dart';
import '../../services/nutrition_service.dart';

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

  Future<void> _loadAchievements() async {
    final unlockedIds = StorageService.getUnlockedAchievements();
    final streak = StorageService.getCurrentStreak();
    final dailyPoints = StorageService.getDailyPoints();
    final workoutCount = StorageService.getAllWorkouts().length;
    final meals = await NutritionService.getAllMeals();
    final mealCount = meals.length;

    final questPoints = StorageService.getQuestPoints();

    final progressMap = {
      'first_workout': workoutCount,
      'first_100_points': dailyPoints,
      'consistency_starter': streak,
      'first_meal_logged': mealCount,
      'world_traveller': questPoints,
      'dedicated': streak,
    };

    setState(() {
      _achievements = Achievements.allAchievements.map((achievement) {
        final isUnlocked = unlockedIds.contains(achievement.id);
        final progress = progressMap[achievement.id] ?? 0;
        return achievement.copyWith(
          isUnlocked: isUnlocked,
          currentProgress: progress,
        );
      }).toList();
    });
  }

  Color _progressColor(Achievement a) {
    switch (a.id) {
      case 'consistency_starter':
      case 'dedicated':
        return Colors.blue[600]!;
      case 'first_meal_logged':
        return Colors.orange[700]!;
      case 'first_100_points':
        return Colors.amber[700]!;
      case 'world_traveller':
        return Colors.amber[800]!;
      default:
        return Colors.blue[600]!;
    }
  }

  String _progressLabel(Achievement a) {
    switch (a.id) {
      case 'consistency_starter':
        final s = a.currentProgress;
        return '$s / ${a.targetValue} days${s > 0 ? ' — keep going!' : ''}';
      case 'dedicated':
        final d = a.currentProgress;
        return '$d / ${a.targetValue} days${d > 0 ? '' : ' — start your streak!'}';
      case 'first_meal_logged':
        return a.currentProgress == 0
            ? '0 / 1 — tap Nutrition to start'
            : '${a.currentProgress} / 1 meals logged';
      case 'first_100_points':
        return '${a.currentProgress} / ${a.targetValue} XP today';
      case 'first_workout':
        return '${a.currentProgress} / 1 workouts logged';
      case 'first_pr':
        return 'Log a workout to set your first PR';
      case 'world_traveller':
        return '${a.currentProgress} / ${a.targetValue} Quest pts';
      default:
        if (a.targetValue != null) {
          return '${a.currentProgress} / ${a.targetValue}';
        }
        return '';
    }
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
          await _loadAchievements();
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _achievements.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final achievement = _achievements[index];
            final showProgress = !achievement.isUnlocked;
            final hasTarget = achievement.targetValue != null;
            final color = _progressColor(achievement);
            final fraction = hasTarget
                ? (achievement.currentProgress / achievement.targetValue!)
                      .clamp(0.0, 1.0)
                : 0.0;

            return Card(
              elevation: achievement.isUnlocked ? 3 : 1,
              color: achievement.isUnlocked ? null : Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon circle
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: achievement.isUnlocked
                            ? Colors.amber[100]
                            : Colors.grey[300],
                      ),
                      child: Center(
                        child: Opacity(
                          opacity: achievement.isUnlocked ? 1.0 : 0.4,
                          child: Text(
                            achievement.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title + description + progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: achievement.isUnlocked
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: achievement.isUnlocked
                                  ? Colors.black87
                                  : Colors.grey[500],
                            ),
                          ),
                          if (showProgress && hasTarget) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 5,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _progressLabel(achievement),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ] else if (showProgress && !hasTarget) ...[
                            const SizedBox(height: 4),
                            Text(
                              _progressLabel(achievement),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Trailing check / checkbox
                    achievement.isUnlocked
                        ? const Icon(Icons.check, color: Colors.green, size: 28)
                        : Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
