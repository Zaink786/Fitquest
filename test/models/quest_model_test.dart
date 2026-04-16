import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest/models/quest_model.dart';

void main() {
  group('getCurrentWorld', () {
    test('0 points returns Training Grounds (world 1)', () {
      final world = getCurrentWorld(0);
      expect(world.id, 1);
      expect(world.name, 'Training Grounds');
    });

    test('exactly 100 points unlocks Grasslands of the East (world 2)', () {
      final world = getCurrentWorld(100);
      expect(world.id, 2);
      expect(world.name, 'Grasslands of the East');
    });

    test('99 points is still Training Grounds', () {
      final world = getCurrentWorld(99);
      expect(world.id, 1);
    });

    test('300 points unlocks Misty Forest (world 3)', () {
      final world = getCurrentWorld(300);
      expect(world.id, 3);
    });

    test('5000 points unlocks Champion\'s Hall (world 10)', () {
      final world = getCurrentWorld(5000);
      expect(world.id, 10);
      expect(world.name, "Champion's Hall");
    });

    test('very large points still returns world 10 (max world)', () {
      final world = getCurrentWorld(999999);
      expect(world.id, 10);
    });

    test('points just below each threshold stay in previous world', () {
      final thresholds = [100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5000];
      for (int i = 0; i < thresholds.length; i++) {
        final world = getCurrentWorld(thresholds[i] - 1);
        expect(world.id, i + 1,
            reason: '${thresholds[i] - 1} pts should be world ${i + 1}');
      }
    });
  });

  group('getNextWorld', () {
    test('0 points: next world is Grasslands (requires 100 pts)', () {
      final next = getNextWorld(0);
      expect(next, isNotNull);
      expect(next!.id, 2);
      expect(next.requiredPoints, 100);
    });

    test('100 points: next world is Misty Forest (requires 300 pts)', () {
      final next = getNextWorld(100);
      expect(next, isNotNull);
      expect(next!.id, 3);
    });

    test('at max world (5000+ pts) returns null', () {
      expect(getNextWorld(5000), isNull);
      expect(getNextWorld(9999), isNull);
    });

    test('4999 points: next world is Champion\'s Hall', () {
      final next = getNextWorld(4999);
      expect(next, isNotNull);
      expect(next!.id, 10);
    });
  });

  group('getWorldProgress', () {
    test('0 points in world 1: progress is 0.0', () {
      expect(getWorldProgress(0), closeTo(0.0, 0.001));
    });

    test('50 points in world 1 (range 0-100): progress is 0.5', () {
      expect(getWorldProgress(50), closeTo(0.5, 0.001));
    });

    test('100 points exactly entering world 2: progress resets to 0.0', () {
      expect(getWorldProgress(100), closeTo(0.0, 0.001));
    });

    test('200 points in world 2 (range 100-300, 100 into range): 0.5', () {
      expect(getWorldProgress(200), closeTo(0.5, 0.001));
    });

    test('at max world progress is 1.0', () {
      expect(getWorldProgress(5000), closeTo(1.0, 0.001));
      expect(getWorldProgress(99999), closeTo(1.0, 0.001));
    });

    test('progress is always between 0.0 and 1.0', () {
      for (int pts = 0; pts <= 5500; pts += 50) {
        final p = getWorldProgress(pts);
        expect(p, inInclusiveRange(0.0, 1.0),
            reason: 'progress out of range at $pts points');
      }
    });
  });

  group('questWorlds list', () {
    test('contains exactly 10 worlds', () {
      expect(questWorlds.length, 10);
    });

    test('worlds are ordered by ascending requiredPoints', () {
      for (int i = 0; i < questWorlds.length - 1; i++) {
        expect(
          questWorlds[i].requiredPoints,
          lessThanOrEqualTo(questWorlds[i + 1].requiredPoints),
        );
      }
    });

    test('first world requires 0 points', () {
      expect(questWorlds.first.requiredPoints, 0);
    });

    test('last world requires 5000 points', () {
      expect(questWorlds.last.requiredPoints, 5000);
    });

    test('each world has a non-empty name and description', () {
      for (final world in questWorlds) {
        expect(world.name, isNotEmpty);
        expect(world.description, isNotEmpty);
      }
    });
  });
}
