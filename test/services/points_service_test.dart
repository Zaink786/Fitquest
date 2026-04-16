import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest/services/points_service.dart';

void main() {
  group('PointsService.calculateStepPoints', () {
    test('0 steps yields 0 points', () {
      expect(PointsService.calculateStepPoints(0), 0);
    });

    test('99 steps yields 0 points (less than 1 full hundred)', () {
      expect(PointsService.calculateStepPoints(99), 0);
    });

    test('100 steps yields 1 point', () {
      expect(PointsService.calculateStepPoints(100), 1);
    });

    test('1000 steps yields 10 points', () {
      expect(PointsService.calculateStepPoints(1000), 10);
    });

    test('10000 steps yields 100 points', () {
      expect(PointsService.calculateStepPoints(10000), 100);
    });

    test('rounds down (integer division): 150 steps = 1 point', () {
      expect(PointsService.calculateStepPoints(150), 1);
    });

    test('rounds down: 199 steps = 1 point', () {
      expect(PointsService.calculateStepPoints(199), 1);
    });

    test('200 steps = 2 points', () {
      expect(PointsService.calculateStepPoints(200), 2);
    });

    test('large step count scales linearly', () {
      expect(PointsService.calculateStepPoints(50000), 500);
    });
  });

  group('PointsService.calculateWorkoutPoints', () {
    test('base points with default multiplier of 1.0 returns base', () {
      expect(PointsService.calculateWorkoutPoints(basePoints: 20), 20);
    });

    test('multiplier of 2.0 doubles base points', () {
      expect(
        PointsService.calculateWorkoutPoints(basePoints: 20, multiplier: 2.0),
        40,
      );
    });

    test('multiplier of 0.5 halves base points', () {
      expect(
        PointsService.calculateWorkoutPoints(basePoints: 20, multiplier: 0.5),
        10,
      );
    });

    test('multiplier of 1.5 rounds correctly (20 * 1.5 = 30)', () {
      expect(
        PointsService.calculateWorkoutPoints(basePoints: 20, multiplier: 1.5),
        30,
      );
    });

    test('result is rounded (not truncated): 10 * 1.5 = 15', () {
      expect(
        PointsService.calculateWorkoutPoints(basePoints: 10, multiplier: 1.5),
        15,
      );
    });

    test('fractional result rounds to nearest int: 10 * 1.3 = 13', () {
      expect(
        PointsService.calculateWorkoutPoints(basePoints: 10, multiplier: 1.3),
        13,
      );
    });

    test('0 base points returns 0 regardless of multiplier', () {
      expect(
        PointsService.calculateWorkoutPoints(basePoints: 0, multiplier: 5.0),
        0,
      );
    });

    test('multiplier of 0 returns 0', () {
      expect(
        PointsService.calculateWorkoutPoints(basePoints: 100, multiplier: 0.0),
        0,
      );
    });
  });
}
