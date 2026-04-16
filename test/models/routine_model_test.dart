import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest/models/routine_model.dart';

void main() {
  group('RoutineExercise', () {
    test('default sets/reps are 3 and 10', () {
      final ex = RoutineExercise(
        exerciseId: 'squat',
        exerciseName: 'Squat',
      );
      expect(ex.sets, 3);
      expect(ex.reps, 10);
      expect(ex.weight, isNull);
    });

    test('can be created with custom values', () {
      final ex = RoutineExercise(
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        sets: 4,
        reps: 8,
        weight: 80.0,
      );
      expect(ex.sets, 4);
      expect(ex.reps, 8);
      expect(ex.weight, 80.0);
    });

    test('toJson serializes all fields', () {
      final ex = RoutineExercise(
        exerciseId: 'deadlift',
        exerciseName: 'Deadlift',
        sets: 5,
        reps: 5,
        weight: 120.0,
      );
      final json = ex.toJson();
      expect(json['exerciseId'], 'deadlift');
      expect(json['exerciseName'], 'Deadlift');
      expect(json['sets'], 5);
      expect(json['reps'], 5);
      expect(json['weight'], 120.0);
    });

    test('fromJson deserializes all fields', () {
      final json = {
        'exerciseId': 'pull-up',
        'exerciseName': 'Pull Up',
        'sets': 3,
        'reps': 12,
        'weight': null,
      };
      final ex = RoutineExercise.fromJson(json);
      expect(ex.exerciseId, 'pull-up');
      expect(ex.exerciseName, 'Pull Up');
      expect(ex.sets, 3);
      expect(ex.reps, 12);
      expect(ex.weight, isNull);
    });

    test('fromJson uses defaults for missing fields', () {
      final ex = RoutineExercise.fromJson({});
      expect(ex.exerciseId, '');
      expect(ex.exerciseName, '');
      expect(ex.sets, 3);
      expect(ex.reps, 10);
      expect(ex.weight, isNull);
    });

    test('round-trip toJson → fromJson preserves data', () {
      final original = RoutineExercise(
        exerciseId: 'lunge',
        exerciseName: 'Lunge',
        sets: 3,
        reps: 15,
        weight: 20.0,
      );
      final restored = RoutineExercise.fromJson(original.toJson());
      expect(restored.exerciseId, original.exerciseId);
      expect(restored.exerciseName, original.exerciseName);
      expect(restored.sets, original.sets);
      expect(restored.reps, original.reps);
      expect(restored.weight, original.weight);
    });

    test('sets and reps are mutable', () {
      final ex = RoutineExercise(exerciseId: 'x', exerciseName: 'X');
      ex.sets = 5;
      ex.reps = 20;
      expect(ex.sets, 5);
      expect(ex.reps, 20);
    });
  });

  group('Routine', () {
    Routine makeRoutine({List<RoutineExercise>? exercises}) {
      return Routine(
        id: 'routine-1',
        name: 'Push Day',
        exercises: exercises ??
            [
              RoutineExercise(
                exerciseId: 'bench',
                exerciseName: 'Bench Press',
                sets: 4,
              ),
              RoutineExercise(
                exerciseId: 'shoulder-press',
                exerciseName: 'Shoulder Press',
                sets: 3,
              ),
            ],
        createdAt: DateTime(2024, 1, 15),
      );
    }

    test('totalSets sums sets across all exercises', () {
      final routine = makeRoutine(); // 4 + 3 = 7
      expect(routine.totalSets, 7);
    });

    test('totalSets is 0 for empty routine', () {
      final routine = makeRoutine(exercises: []);
      expect(routine.totalSets, 0);
    });

    test('totalSets counts a single exercise', () {
      final routine = makeRoutine(
        exercises: [
          RoutineExercise(exerciseId: 'x', exerciseName: 'X', sets: 5),
        ],
      );
      expect(routine.totalSets, 5);
    });

    test('toJson serializes id, name, exercises, createdAt', () {
      final routine = makeRoutine(exercises: []);
      final json = routine.toJson();
      expect(json['id'], 'routine-1');
      expect(json['name'], 'Push Day');
      expect(json['exercises'], isEmpty);
      expect(json['createdAt'], isNotEmpty);
    });

    test('toJson includes serialized exercises', () {
      final routine = makeRoutine();
      final json = routine.toJson();
      final exercises = json['exercises'] as List;
      expect(exercises.length, 2);
      expect(exercises[0]['exerciseId'], 'bench');
    });

    test('fromJson deserializes routine with exercises', () {
      final json = {
        'id': 'r2',
        'name': 'Pull Day',
        'exercises': [
          {
            'exerciseId': 'pull-up',
            'exerciseName': 'Pull Up',
            'sets': 4,
            'reps': 10,
            'weight': null,
          }
        ],
        'createdAt': '2024-03-01T08:00:00.000',
      };

      final routine = Routine.fromJson(json);
      expect(routine.id, 'r2');
      expect(routine.name, 'Pull Day');
      expect(routine.exercises.length, 1);
      expect(routine.exercises[0].exerciseId, 'pull-up');
      expect(routine.createdAt, DateTime(2024, 3, 1, 8, 0, 0));
    });

    test('fromJson uses defaults for missing fields', () {
      final routine = Routine.fromJson({});
      expect(routine.id, '');
      expect(routine.name, '');
      expect(routine.exercises, isEmpty);
    });

    test('round-trip toJson → fromJson preserves data', () {
      final original = makeRoutine();
      final restored = Routine.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.exercises.length, original.exercises.length);
      expect(restored.totalSets, original.totalSets);
    });
  });
}
