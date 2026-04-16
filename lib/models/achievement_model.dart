class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int? targetValue;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;
  final bool isDaily;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon = '🏆',
    this.targetValue,
    this.currentProgress = 0,
    required this.isUnlocked,
    this.unlockedAt,
    this.xpReward = 0,
    this.isDaily = false,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? targetValue,
    int? currentProgress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
    bool? isDaily,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
      isDaily: isDaily ?? this.isDaily,
    );
  }
}

// Predefined achievements
class Achievements {
  static Achievement get dailyWorkout => Achievement(
    id: 'daily_workout',
    title: 'Daily Warrior',
    description: 'Complete a workout today',
    icon: '💪',
    targetValue: 1,
    isUnlocked: false,
    xpReward: 50,
    isDaily: true,
  );

  static Achievement get dailyNutrition => Achievement(
    id: 'daily_nutrition',
    title: 'Healthy Eater',
    description: 'Log 3 meals today',
    icon: '🥗',
    targetValue: 3,
    isUnlocked: false,
    xpReward: 30,
    isDaily: true,
  );

  static Achievement get dailySteps => Achievement(
    id: 'daily_steps',
    title: 'Step Master',
    description: 'Reach 5,000 steps today',
    icon: '👣',
    targetValue: 5000,
    isUnlocked: false,
    xpReward: 40,
    isDaily: true,
  );

  static Achievement get first100Points => Achievement(
    id: 'first_100_points',
    title: 'Century Club',
    description: 'Earned 100 points in a single day!',
    icon: '💯',
    targetValue: 100,
    isUnlocked: false,
    xpReward: 100,
  );

  static Achievement get firstWorkout => Achievement(
    id: 'first_workout',
    title: 'Getting Started',
    description: 'Logged your first workout!',
    icon: '🎯',
    isUnlocked: false,
    xpReward: 50,
  );

  static Achievement get consistencyStarter => Achievement(
    id: 'consistency_starter',
    title: 'Consistency Starter',
    description: 'Maintained a 3-day workout streak.',
    icon: '🔥',
    targetValue: 3,
    isUnlocked: false,
    xpReward: 150,
  );

  static Achievement get firstMealLogged => Achievement(
    id: 'first_meal_logged',
    title: 'Log a Meal',
    description: 'Logged your first meal!',
    icon: '🍽️',
    isUnlocked: false,
    xpReward: 20,
  );

  static Achievement get firstPr => Achievement(
    id: 'first_pr',
    title: 'First PR',
    description: 'Beat a personal record.',
    icon: '⚡',
    isUnlocked: false,
    xpReward: 75,
  );

  static Achievement get worldTraveller => Achievement(
    id: 'world_traveller',
    title: 'World Traveller',
    description: 'Unlock your second world.',
    icon: '🌍',
    targetValue: 100,
    isUnlocked: false,
    xpReward: 500,
  );

  static Achievement get dedicated => Achievement(
    id: 'dedicated',
    title: 'Dedicated',
    description: 'Maintain a 7-day streak.',
    icon: '💪',
    targetValue: 7,
    isUnlocked: false,
    xpReward: 300,
  );

  static List<Achievement> get allAchievements => [
    dailyWorkout,
    dailyNutrition,
    dailySteps,
    firstWorkout,
    first100Points,
    firstPr,
    consistencyStarter,
    firstMealLogged,
    worldTraveller,
    dedicated,
  ];
}
