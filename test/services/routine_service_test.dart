import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitquest/services/routine_service.dart';
import 'package:fitquest/models/routine_model.dart';

Routine makeRoutine({
  String id = 'r1',
  String name = 'Push Day',
  int setCount = 3,
}) {
  return Routine(
    id: id,
    name: name,
    exercises: [
      RoutineExercise(
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        sets: setCount,
      ),
    ],
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoutineService.getRoutines', () {
    test('returns empty list when no routines saved', () async {
      final routines = await RoutineService.getRoutines();
      expect(routines, isEmpty);
    });
  });

  group('RoutineService.saveRoutine', () {
    test('saves a routine and it can be retrieved', () async {
      final routine = makeRoutine(id: 'r1', name: 'Push Day');
      await RoutineService.saveRoutine(routine);

      final routines = await RoutineService.getRoutines();
      expect(routines.length, 1);
      expect(routines[0].id, 'r1');
      expect(routines[0].name, 'Push Day');
    });

    test('saving multiple routines stores all of them', () async {
      await RoutineService.saveRoutine(makeRoutine(id: 'r1', name: 'Push'));
      await RoutineService.saveRoutine(makeRoutine(id: 'r2', name: 'Pull'));
      await RoutineService.saveRoutine(makeRoutine(id: 'r3', name: 'Legs'));

      final routines = await RoutineService.getRoutines();
      expect(routines.length, 3);
      final ids = routines.map((r) => r.id).toList();
      expect(ids, containsAll(['r1', 'r2', 'r3']));
    });

    test('saving routine with existing id replaces it (update)', () async {
      await RoutineService.saveRoutine(makeRoutine(id: 'r1', name: 'Old Name'));
      await RoutineService.saveRoutine(makeRoutine(id: 'r1', name: 'New Name'));

      final routines = await RoutineService.getRoutines();
      expect(routines.length, 1);
      expect(routines[0].name, 'New Name');
    });

    test('update preserves other routines', () async {
      await RoutineService.saveRoutine(makeRoutine(id: 'r1', name: 'Push'));
      await RoutineService.saveRoutine(makeRoutine(id: 'r2', name: 'Pull'));
      await RoutineService.saveRoutine(makeRoutine(id: 'r1', name: 'Push Updated'));

      final routines = await RoutineService.getRoutines();
      expect(routines.length, 2);

      final names = routines.map((r) => r.name).toList();
      expect(names, contains('Push Updated'));
      expect(names, contains('Pull'));
    });

    test('persists exercises within a routine', () async {
      final routine = Routine(
        id: 'r1',
        name: 'Full Body',
        exercises: [
          RoutineExercise(
            exerciseId: 'squat',
            exerciseName: 'Squat',
            sets: 4,
            reps: 8,
            weight: 100.0,
          ),
          RoutineExercise(
            exerciseId: 'bench',
            exerciseName: 'Bench Press',
            sets: 3,
            reps: 10,
          ),
        ],
        createdAt: DateTime(2024, 6, 1),
      );

      await RoutineService.saveRoutine(routine);
      final loaded = (await RoutineService.getRoutines()).first;

      expect(loaded.exercises.length, 2);
      expect(loaded.exercises[0].exerciseId, 'squat');
      expect(loaded.exercises[0].weight, 100.0);
      expect(loaded.exercises[1].exerciseId, 'bench');
    });
  });

  group('RoutineService.deleteRoutine', () {
    test('deletes a routine by id', () async {
      await RoutineService.saveRoutine(makeRoutine(id: 'r1'));
      await RoutineService.deleteRoutine('r1');

      final routines = await RoutineService.getRoutines();
      expect(routines, isEmpty);
    });

    test('deleting non-existent id does not throw', () async {
      await RoutineService.saveRoutine(makeRoutine(id: 'r1'));
      await expectLater(
        RoutineService.deleteRoutine('does-not-exist'),
        completes,
      );
      // Original routine should still be there
      final routines = await RoutineService.getRoutines();
      expect(routines.length, 1);
    });

    test('deletes only the targeted routine', () async {
      await RoutineService.saveRoutine(makeRoutine(id: 'r1', name: 'Push'));
      await RoutineService.saveRoutine(makeRoutine(id: 'r2', name: 'Pull'));
      await RoutineService.saveRoutine(makeRoutine(id: 'r3', name: 'Legs'));

      await RoutineService.deleteRoutine('r2');

      final routines = await RoutineService.getRoutines();
      expect(routines.length, 2);
      final ids = routines.map((r) => r.id).toList();
      expect(ids, containsAll(['r1', 'r3']));
      expect(ids, isNot(contains('r2')));
    });

    test('delete all routines one by one leaves empty list', () async {
      await RoutineService.saveRoutine(makeRoutine(id: 'r1'));
      await RoutineService.saveRoutine(makeRoutine(id: 'r2'));

      await RoutineService.deleteRoutine('r1');
      await RoutineService.deleteRoutine('r2');

      expect(await RoutineService.getRoutines(), isEmpty);
    });
  });
}
