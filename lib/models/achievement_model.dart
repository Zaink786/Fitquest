class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int? targetValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon = '🏆',
    this.targetValue,
    required this.isUnlocked,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? targetValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      targetValue: targetValue ?? this.targetValue,
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

  static Achievement get first5000Steps => Achievement(
    id: 'first_5000_steps',
    title: 'Step Master',
    description: 'Hit 5,000 steps in a single day.',
    icon: '👟',
    targetValue: 5000,
    isUnlocked: false,
  );

  static List<Achievement> get allAchievements => [
    first100Points,
    firstWorkout,
    consistencyStarter,
    first5000Steps,
  ];
}
