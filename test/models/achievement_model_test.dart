import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest/models/achievement_model.dart';

void main() {
  group('Achievement.copyWith', () {
    final base = Achievement(
      id: 'first_workout',
      title: 'Getting Started',
      description: 'Logged your first workout!',
      icon: '🎯',
      isUnlocked: false,
    );

    test('copyWith with no args returns identical values', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.title, base.title);
      expect(copy.description, base.description);
      expect(copy.icon, base.icon);
      expect(copy.isUnlocked, base.isUnlocked);
      expect(copy.unlockedAt, base.unlockedAt);
    });

    test('copyWith can update isUnlocked', () {
      final unlocked = base.copyWith(isUnlocked: true);
      expect(unlocked.isUnlocked, true);
      expect(unlocked.id, base.id); // unchanged
    });

    test('copyWith can set unlockedAt timestamp', () {
      final now = DateTime(2024, 6, 1, 10, 30);
      final unlocked = base.copyWith(isUnlocked: true, unlockedAt: now);
      expect(unlocked.unlockedAt, now);
    });

    test('copyWith can update progress', () {
      final progressed = base.copyWith(currentProgress: 50);
      expect(progressed.currentProgress, 50);
      expect(progressed.isUnlocked, false); // not changed
    });

    test('copyWith does not mutate the original', () {
      base.copyWith(isUnlocked: true);
      expect(base.isUnlocked, false);
    });

    test('copyWith can change title and description', () {
      final renamed = base.copyWith(
        title: 'New Title',
        description: 'New description',
      );
      expect(renamed.title, 'New Title');
      expect(renamed.description, 'New description');
    });
  });

  group('Achievements factory getters', () {
    test('firstWorkout has correct id and is initially locked', () {
      final a = Achievements.firstWorkout;
      expect(a.id, 'first_workout');
      expect(a.isUnlocked, false);
    });

    test('first100Points has targetValue of 100', () {
      final a = Achievements.first100Points;
      expect(a.id, 'first_100_points');
      expect(a.targetValue, 100);
      expect(a.isUnlocked, false);
    });

    test('consistencyStarter has targetValue of 3', () {
      final a = Achievements.consistencyStarter;
      expect(a.targetValue, 3);
    });

    test('dedicated has targetValue of 7', () {
      final a = Achievements.dedicated;
      expect(a.targetValue, 7);
    });

    test('firstMealLogged has correct id', () {
      expect(Achievements.firstMealLogged.id, 'first_meal_logged');
    });

    test('firstPr has correct id', () {
      expect(Achievements.firstPr.id, 'first_pr');
    });

    test('worldTraveller has targetValue of 100', () {
      final a = Achievements.worldTraveller;
      expect(a.id, 'world_traveller');
      expect(a.targetValue, 100);
    });

    test('each getter returns a fresh instance (not the same object)', () {
      final a1 = Achievements.firstWorkout;
      final a2 = Achievements.firstWorkout;
      expect(identical(a1, a2), false);
    });
  });

  group('Achievements.allAchievements', () {
    test('contains exactly 10 achievements', () {
      expect(Achievements.allAchievements.length, 10);
    });

    test('contains the expected achievement ids', () {
      final ids = Achievements.allAchievements.map((a) => a.id).toSet();
      expect(
        ids,
        {
          'daily_workout',
          'daily_nutrition',
          'daily_steps',
          'first_workout',
          'first_100_points',
          'first_pr',
          'consistency_starter',
          'first_meal_logged',
          'world_traveller',
          'dedicated',
        },
      );
    });

    test('all achievements are initially unlocked=false', () {
      for (final a in Achievements.allAchievements) {
        expect(a.isUnlocked, false,
            reason: '${a.id} should start locked');
      }
    });

    test('all achievements have non-empty id, title, description', () {
      for (final a in Achievements.allAchievements) {
        expect(a.id, isNotEmpty);
        expect(a.title, isNotEmpty);
        expect(a.description, isNotEmpty);
      }
    });

    test('all achievement ids are unique', () {
      final ids = Achievements.allAchievements.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
