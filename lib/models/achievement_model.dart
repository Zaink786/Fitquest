class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int? targetValue;
  final int currentProgress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon = '🏆',
    this.targetValue,
    this.currentProgress = 0,
    required this.isUnlocked,
    this.unlockedAt,
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
    );
  }
}

// Predefined achievements
class Achievements {
  static Achievement get first100Points => Achievement(
    id: 'first_100_points',
    title: 'Century Club',
    description: 'Earned 100 points in a single day!',
    icon: '💯',
    targetValue: 100,
    isUnlocked: false,
  );

  static Achievement get firstWorkout => Achievement(
    id: 'first_workout',
    title: 'Getting Started',
    description: 'Logged your first workout!',
    icon: '🎯',
    isUnlocked: false,
  );

  static Achievement get consistencyStarter => Achievement(
    id: 'consistency_starter',
    title: 'Consistency Starter',
    description: 'Maintained a 3-day workout streak.',
    icon: '🔥',
    targetValue: 3,
    isUnlocked: false,
  );

  static Achievement get firstMealLogged => Achievement(
    id: 'first_meal_logged',
    title: 'Log a Meal',
    description: 'Logged your first meal!',
    icon: '🍽️',
    isUnlocked: false,
  );

  static Achievement get firstPr => Achievement(
    id: 'first_pr',
    title: 'First PR',
    description: 'Beat a personal record.',
    icon: '⚡',
    isUnlocked: false,
  );

  static Achievement get worldTraveller => Achievement(
    id: 'world_traveller',
    title: 'World Traveller',
    description: 'Unlock your second world.',
    icon: '🌍',
    targetValue: 100,
    isUnlocked: false,
  );

  static Achievement get dedicated => Achievement(
    id: 'dedicated',
    title: 'Dedicated',
    description: 'Maintain a 7-day streak.',
    icon: '💪',
    targetValue: 7,
    isUnlocked: false,
  );

  static List<Achievement> get allAchievements => [
    firstWorkout,
    first100Points,
    firstPr,
    consistencyStarter,
    firstMealLogged,
    worldTraveller,
    dedicated,
  ];
}
