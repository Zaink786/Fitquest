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
    // Reset daily achievements at the start so they always refresh on a new day,
    // even if the user never completes a daily goal that session.
    await StorageService.resetDailyAchievementsIfNeeded();

    final streak = StorageService.getCurrentStreak();
    final dailyPoints = StorageService.getDailyPoints();
    final questPoints = StorageService.getQuestPoints();

    // Use today's data for daily-scoped achievements.
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final allWorkouts = StorageService.getAllWorkouts();
    final todayWorkouts = allWorkouts
        .where((w) => !w.date.isBefore(todayStart))
        .length;
    final todayMeals = await NutritionService.getTodaysMeals();
    final todayMealCount = todayMeals.length;
    final todaySteps = StorageService.getTodaySteps();

    final progressMap = <String, int>{
      'daily_workout': todayWorkouts,
      'daily_nutrition': todayMealCount,
      'daily_steps': todaySteps,
      'first_workout': todayWorkouts,
      'first_100_points': dailyPoints,
      'consistency_starter': streak,
      'first_meal_logged': todayMealCount,
      'world_traveller': questPoints,
      'dedicated': streak,
    };

    // Auto-unlock any achievement whose progress meets its target.
    for (final a in Achievements.allAchievements) {
      final progress = progressMap[a.id] ?? 0;
      final target =
          a.targetValue ?? 1; // Default to 1 if null (like first_workout)

      if (progress >= target) {
        if (!StorageService.isAchievementUnlocked(a.id)) {
          if (a.id == 'daily_workout') {
            await StorageService.checkDailyWorkout();
          } else if (a.id == 'daily_nutrition') {
            await StorageService.checkDailyNutrition(progress);
          } else if (a.id == 'daily_steps') {
            await StorageService.checkDailySteps(progress);
          } else {
            await StorageService.unlockAchievement(a.id);
          }
        }
      }
    }

    final unlockedIds = StorageService.getUnlockedAchievements();

    final mapped = Achievements.allAchievements.map((achievement) {
      final isUnlocked = unlockedIds.contains(achievement.id);
      final progress = progressMap[achievement.id] ?? 0;
      return achievement.copyWith(
        isUnlocked: isUnlocked,
        currentProgress: progress,
      );
    }).toList();

    // Split achievements
    final daily = mapped.where((a) => a.isDaily).toList();
    final regular = mapped.where((a) => !a.isDaily).toList();

    regular.sort((a, b) {
      if (a.isUnlocked == b.isUnlocked) return 0;
      return a.isUnlocked ? -1 : 1;
    });

    setState(() {
      _achievements = [...daily, ...regular];
    });
  }

  Color _progressColor(Achievement a) {
    if (a.isDaily) return Colors.orange;
    switch (a.id) {
      case 'consistency_starter':
      case 'dedicated':
        return const Color(0xFF9FA8DA);
      case 'first_meal_logged':
        return const Color(0xFFE65100);
      case 'first_100_points':
        return const Color(0xFF9C27B0);
      case 'world_traveller':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9FA8DA);
    }
  }

  String _progressLabel(Achievement a) {
    if (a.isDaily) {
      if (a.isUnlocked) return 'Reward claimed!';
      return '${a.currentProgress} / ${a.targetValue} ${a.id == 'daily_steps' ? 'steps' : (a.id == 'daily_nutrition' ? 'meals' : 'workout')}';
    }
    switch (a.id) {
      case 'consistency_starter':
        final s = a.currentProgress;
        return '$s / ${a.targetValue} days${s > 0 ? ' — keep going!' : ''}';
      case 'dedicated':
        final d = a.currentProgress;
        return '$d / ${a.targetValue} days${d > 0 ? '' : ' — start your streak!'}';
      case 'first_meal_logged':
        return a.isUnlocked
            ? 'Success!'
            : (a.currentProgress == 0
                  ? '0 / 1 — tap Nutrition'
                  : '${a.currentProgress} / 1 meal');
      case 'first_100_points':
        return '${a.currentProgress} / ${a.targetValue} XP today';
      case 'first_workout':
        return a.isUnlocked ? 'Logged!' : '0 / 1 workouts logged';
      case 'first_pr':
        return a.isUnlocked ? 'Smashed!' : 'Log a workout to set a PR';
      case 'world_traveller':
        return '${a.currentProgress} / ${a.targetValue} QP';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAchievements,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            // index 0 is the title header; achievements start at index 1
            itemCount: _achievements.length + 1,
            separatorBuilder: (_, index) => index == 0
                ? const SizedBox(height: 20)
                : const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$unlockedCount/${_achievements.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                );
              }
              final achievement = _achievements[index - 1];
              final showProgress = !achievement.isUnlocked;
              final hasTarget = achievement.targetValue != null;
              final color = _progressColor(achievement);
              final fraction = hasTarget
                  ? (achievement.currentProgress / achievement.targetValue!)
                        .clamp(0.0, 1.0)
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 1 && achievement.isDaily)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12, left: 4),
                      child: Text(
                        'Daily Goals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (index > 1 &&
                      !achievement.isDaily &&
                      _achievements[index - 2].isDaily)
                    const Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 12, left: 4),
                      child: Text(
                        'Milestones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Card(
                    elevation: achievement.isUnlocked ? 3 : 1,
                    color: achievement.isUnlocked
                        ? (achievement.isDaily
                              ? (isDark
                                    ? Colors.orange[900]?.withOpacity(0.2)
                                    : Colors.orange[50])
                              : null)
                        : (isDark ? Colors.grey[850] : Colors.grey[100]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: achievement.isDaily && !achievement.isUnlocked
                          ? BorderSide(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
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
                                  ? (achievement.isDaily
                                        ? Colors.orange[400]
                                        : (isDark
                                              ? Colors.amber[800]
                                              : Colors.amber[100]))
                                  : (isDark
                                        ? Colors.grey[700]
                                        : Colors.grey[300]),
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
                                Row(
                                  children: [
                                    Text(
                                      achievement.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: achievement.isUnlocked
                                            ? null
                                            : (isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600]),
                                      ),
                                    ),
                                    if (achievement.xpReward > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '+${achievement.xpReward} XP',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  achievement.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: achievement.isUnlocked
                                        ? null
                                        : (isDark
                                              ? Colors.grey[500]
                                              : Colors.grey[500]),
                                  ),
                                ),
                                if (showProgress && hasTarget) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: fraction,
                                      minHeight: 3,
                                      backgroundColor: isDark
                                          ? Colors.grey[800]
                                          : const Color(0xFFF3E5F5),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _progressLabel(achievement),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ] else if (showProgress && !hasTarget) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _progressLabel(achievement),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ] else if (achievement.isUnlocked &&
                                    achievement.isDaily) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Completed Today',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Trailing check / checkbox
                          achievement.isUnlocked
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 28,
                                )
                              : Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.grey[600]!
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
