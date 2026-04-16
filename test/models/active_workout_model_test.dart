import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest/models/active_workout_model.dart';

void main() {
  group('ActiveSet', () {
    test('default values: reps=10, isDone=false, kg=null', () {
      final set = ActiveSet();
      expect(set.reps, 10);
      expect(set.isDone, false);
      expect(set.kg, isNull);
    });

    test('can be created with custom values', () {
      final set = ActiveSet(kg: 80.0, reps: 5, isDone: true);
      expect(set.kg, 80.0);
      expect(set.reps, 5);
      expect(set.isDone, true);
    });

    test('kg can be set after creation', () {
      final set = ActiveSet();
      set.kg = 60.0;
      expect(set.kg, 60.0);
    });

    test('isDone can be toggled', () {
      final set = ActiveSet();
      expect(set.isDone, false);
      set.isDone = true;
      expect(set.isDone, true);
    });
  });

  group('ActiveExerciseEntry', () {
    ActiveExerciseEntry makeEntry({int setCount = 3, bool allDone = false}) {
      return ActiveExerciseEntry(
        exerciseId: 'bench-press',
        exerciseName: 'Bench Press',
        sets: List.generate(
          setCount,
          (_) => ActiveSet(kg: 100.0, reps: 8, isDone: allDone),
        ),
      );
    }

    test('completedSets is 0 when no sets are done', () {
      final entry = makeEntry(setCount: 3, allDone: false);
      expect(entry.completedSets, 0);
    });

    test('completedSets counts only done sets', () {
      final entry = ActiveExerciseEntry(
        exerciseId: 'squat',
        exerciseName: 'Squat',
        sets: [
          ActiveSet(isDone: true),
          ActiveSet(isDone: false),
          ActiveSet(isDone: true),
        ],
      );
      expect(entry.completedSets, 2);
    });

    test('completedSets equals setCount when all sets are done', () {
      final entry = makeEntry(setCount: 4, allDone: true);
      expect(entry.completedSets, 4);
    });

    test('isFullyComplete is false when no sets done', () {
      final entry = makeEntry(setCount: 3, allDone: false);
      expect(entry.isFullyComplete, false);
    });

    test('isFullyComplete is true when all sets done', () {
      final entry = makeEntry(setCount: 3, allDone: true);
      expect(entry.isFullyComplete, true);
    });

    test('isFullyComplete is false when only some sets done', () {
      final entry = ActiveExerciseEntry(
        exerciseId: 'pull-up',
        exerciseName: 'Pull Up',
        sets: [
          ActiveSet(isDone: true),
          ActiveSet(isDone: false),
        ],
      );
      expect(entry.isFullyComplete, false);
    });

    test('isFullyComplete is false when sets list is empty', () {
      final entry = ActiveExerciseEntry(
        exerciseId: 'plank',
        exerciseName: 'Plank',
        sets: [],
      );
      expect(entry.isFullyComplete, false);
    });

    test('marking a set done updates completedSets immediately', () {
      final entry = makeEntry(setCount: 2, allDone: false);
      expect(entry.completedSets, 0);
      entry.sets[0].isDone = true;
      expect(entry.completedSets, 1);
      entry.sets[1].isDone = true;
      expect(entry.completedSets, 2);
      expect(entry.isFullyComplete, true);
    });
  });
}
