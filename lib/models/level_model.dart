/// XP thresholds for each level.
/// Level 1 starts at 0 XP; each subsequent level requires more XP.
class LevelSystem {
  /// Points needed to *complete* each level (index = level - 1).
  /// Level 1: 0→50, Level 2: 50→120, Level 3: 120→210 ...
  static const List<int> _thresholds = [
    50, // Level 1 → 2
    70, // Level 2 → 3
    90, // Level 3 → 4
    120, // Level 4 → 5
    150, // Level 5 → 6
    180, // Level 6 → 7
    220, // Level 7 → 8
    260, // Level 8 → 9
    300, // Level 9 → 10
    350, // Level 10 → 11
    400, // Level 11 → 12
    450, // Level 12 → 13
    500, // Level 13 → 14
    600, // Level 14 → 15
    700, // Level 15 → 16
    800, // Level 16 → 17
    900, // Level 17 → 18
    1000, // Level 18 → 19
    1200, // Level 19 → 20
    1500, // Level 20 → 21  (and so on)
  ];

  /// Get the cumulative XP required to reach a given level.
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    int total = 0;
    for (int i = 0; i < level - 1; i++) {
      total += i < _thresholds.length
          ? _thresholds[i]
          : _thresholds.last + (i - _thresholds.length + 1) * 200;
    }
    return total;
  }

  /// Determine current level info from total XP.
  static LevelInfo fromTotalXp(int totalXp) {
    int level = 1;
    int cumulative = 0;

    while (true) {
      final idx = level - 1;
      final needed = idx < _thresholds.length
          ? _thresholds[idx]
          : _thresholds.last + (idx - _thresholds.length + 1) * 200;

      if (totalXp < cumulative + needed) {
        // Still in this level
        final xpIntoLevel = totalXp - cumulative;
        return LevelInfo(
          level: level,
          currentXp: totalXp,
          xpIntoLevel: xpIntoLevel,
          xpForNextLevel: needed,
          progress: xpIntoLevel / needed,
        );
      }

      cumulative += needed;
      level++;
    }
  }

  /// Convenience: points required to finish the current level.
  static int xpRemainingForNextLevel(int totalXp) {
    final info = fromTotalXp(totalXp);
    return info.xpForNextLevel - info.xpIntoLevel;
  }
}

/// Snapshot of a user's level status.
class LevelInfo {
  final int level;
  final int currentXp;
  final int xpIntoLevel; // how far into the current level
  final int xpForNextLevel; // total XP span of this level
  final double progress; // 0.0 → 1.0

  const LevelInfo({
    required this.level,
    required this.currentXp,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.progress,
  });
}
