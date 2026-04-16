import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest/models/level_model.dart';

void main() {
  group('LevelSystem.xpForLevel', () {
    test('level 1 requires 0 XP', () {
      expect(LevelSystem.xpForLevel(1), 0);
    });

    test('level 2 requires 50 XP (first threshold)', () {
      expect(LevelSystem.xpForLevel(2), 50);
    });

    test('level 3 requires 120 XP (50 + 70)', () {
      expect(LevelSystem.xpForLevel(3), 120);
    });

    test('level 4 requires 210 XP (50 + 70 + 90)', () {
      expect(LevelSystem.xpForLevel(4), 210);
    });

    test('level 0 or negative treated as level 1 (returns 0)', () {
      expect(LevelSystem.xpForLevel(0), 0);
      expect(LevelSystem.xpForLevel(-5), 0);
    });

    test('XP required is strictly increasing with each level', () {
      for (int i = 1; i <= 15; i++) {
        expect(
          LevelSystem.xpForLevel(i + 1),
          greaterThan(LevelSystem.xpForLevel(i)),
        );
      }
    });
  });

  group('LevelSystem.fromTotalXp', () {
    test('0 XP is level 1, progress 0.0', () {
      final info = LevelSystem.fromTotalXp(0);
      expect(info.level, 1);
      expect(info.currentXp, 0);
      expect(info.xpIntoLevel, 0);
      expect(info.progress, 0.0);
    });

    test('25 XP is level 1, halfway through (50 needed)', () {
      final info = LevelSystem.fromTotalXp(25);
      expect(info.level, 1);
      expect(info.xpIntoLevel, 25);
      expect(info.xpForNextLevel, 50);
      expect(info.progress, closeTo(0.5, 0.001));
    });

    test('50 XP exactly reaches level 2', () {
      final info = LevelSystem.fromTotalXp(50);
      expect(info.level, 2);
      expect(info.xpIntoLevel, 0);
      expect(info.progress, 0.0);
    });

    test('49 XP is still level 1', () {
      final info = LevelSystem.fromTotalXp(49);
      expect(info.level, 1);
    });

    test('120 XP exactly reaches level 3', () {
      final info = LevelSystem.fromTotalXp(120);
      expect(info.level, 3);
      expect(info.xpIntoLevel, 0);
    });

    test('progress is clamped between 0.0 and 1.0', () {
      for (int xp = 0; xp <= 5000; xp += 100) {
        final info = LevelSystem.fromTotalXp(xp);
        expect(info.progress, inInclusiveRange(0.0, 1.0));
      }
    });

    test('xpIntoLevel + xpRemaining equals xpForNextLevel', () {
      final info = LevelSystem.fromTotalXp(75); // 75 - 50 = 25 into level 2
      expect(info.xpIntoLevel + (info.xpForNextLevel - info.xpIntoLevel),
          info.xpForNextLevel);
    });

    test('currentXp is always the input totalXp', () {
      final xpValues = [0, 1, 50, 120, 500, 1000, 9999];
      for (final xp in xpValues) {
        expect(LevelSystem.fromTotalXp(xp).currentXp, xp);
      }
    });
  });

  group('LevelSystem.xpRemainingForNextLevel', () {
    test('at 0 XP, 50 remaining to next level', () {
      expect(LevelSystem.xpRemainingForNextLevel(0), 50);
    });

    test('at 25 XP (level 1), 25 remaining', () {
      expect(LevelSystem.xpRemainingForNextLevel(25), 25);
    });

    test('at exactly level boundary, remaining equals full next level span', () {
      // At 50 XP we are at the start of level 2 (needs 70 to reach level 3)
      expect(LevelSystem.xpRemainingForNextLevel(50), 70);
    });
  });

  group('LevelInfo', () {
    test('can be constructed directly', () {
      const info = LevelInfo(
        level: 5,
        currentXp: 500,
        xpIntoLevel: 50,
        xpForNextLevel: 150,
        progress: 0.333,
      );
      expect(info.level, 5);
      expect(info.currentXp, 500);
      expect(info.xpIntoLevel, 50);
      expect(info.xpForNextLevel, 150);
      expect(info.progress, closeTo(0.333, 0.001));
    });
  });
}
