import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest/models/exercise_model.dart';

void main() {
  group('Exercise.fromJson', () {
    test('parses a full JSON object correctly', () {
      final json = {
        'id': 'bench-press',
        'name': 'Bench Press',
        'force': 'push',
        'level': 'intermediate',
        'mechanic': 'compound',
        'equipment': 'barbell',
        'primaryMuscles': ['chest'],
        'secondaryMuscles': ['shoulders', 'triceps'],
        'instructions': ['Lie on bench', 'Push bar up'],
        'category': 'strength',
        'images': ['bench1.png'],
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.id, 'bench-press');
      expect(exercise.name, 'Bench Press');
      expect(exercise.force, 'push');
      expect(exercise.level, 'intermediate');
      expect(exercise.mechanic, 'compound');
      expect(exercise.equipment, 'barbell');
      expect(exercise.primaryMuscles, ['chest']);
      expect(exercise.secondaryMuscles, ['shoulders', 'triceps']);
      expect(exercise.instructions, ['Lie on bench', 'Push bar up']);
      expect(exercise.category, 'strength');
      expect(exercise.images, ['bench1.png']);
    });

    test('uses name as id when id field is absent', () {
      final json = {
        'name': 'Push Up',
        'level': 'beginner',
        'primaryMuscles': ['chest'],
        'secondaryMuscles': [],
        'instructions': [],
        'category': 'strength',
      };
      final exercise = Exercise.fromJson(json);
      expect(exercise.id, 'Push Up');
    });

    test('defaults level to beginner when missing', () {
      final json = {
        'id': 'x',
        'name': 'Mystery Exercise',
        'primaryMuscles': [],
        'secondaryMuscles': [],
        'instructions': [],
        'category': 'cardio',
      };
      final exercise = Exercise.fromJson(json);
      expect(exercise.level, 'beginner');
    });

    test('optional fields default to null/empty when absent', () {
      final json = {
        'id': 'plank',
        'name': 'Plank',
        'level': 'beginner',
        'primaryMuscles': [],
        'secondaryMuscles': [],
        'instructions': [],
        'category': 'core',
      };
      final exercise = Exercise.fromJson(json);
      expect(exercise.force, isNull);
      expect(exercise.mechanic, isNull);
      expect(exercise.equipment, isNull);
      expect(exercise.images, isNull);
    });
  });

  group('Exercise.toJson', () {
    test('serializes all fields back to JSON', () {
      final exercise = Exercise(
        id: 'deadlift',
        name: 'Deadlift',
        force: 'pull',
        level: 'expert',
        mechanic: 'compound',
        equipment: 'barbell',
        primaryMuscles: ['hamstrings', 'glutes'],
        secondaryMuscles: ['lower back'],
        instructions: ['Stand with feet hip-width'],
        category: 'strength',
        images: null,
      );

      final json = exercise.toJson();

      expect(json['id'], 'deadlift');
      expect(json['name'], 'Deadlift');
      expect(json['force'], 'pull');
      expect(json['level'], 'expert');
      expect(json['equipment'], 'barbell');
      expect(json['primaryMuscles'], ['hamstrings', 'glutes']);
      expect(json['secondaryMuscles'], ['lower back']);
      expect(json['category'], 'strength');
    });

    test('round-trip fromJson → toJson preserves all data', () {
      final original = {
        'id': 'squat',
        'name': 'Squat',
        'force': 'push',
        'level': 'intermediate',
        'mechanic': 'compound',
        'equipment': 'barbell',
        'primaryMuscles': ['quadriceps'],
        'secondaryMuscles': ['glutes', 'hamstrings'],
        'instructions': ['Stand with bar on back', 'Bend knees'],
        'category': 'strength',
        'images': null,
      };

      final exercise = Exercise.fromJson(original);
      final restored = exercise.toJson();

      expect(restored['id'], original['id']);
      expect(restored['name'], original['name']);
      expect(restored['level'], original['level']);
      expect(restored['primaryMuscles'], original['primaryMuscles']);
    });
  });

  group('Exercise.getBasePoints', () {
    test('always returns 20 regardless of category or level', () {
      final levels = ['beginner', 'intermediate', 'expert'];
      final categories = ['strength', 'cardio', 'stretching', 'plyometrics'];

      for (final level in levels) {
        for (final category in categories) {
          final exercise = Exercise(
            id: 'x',
            name: 'X',
            level: level,
            primaryMuscles: [],
            secondaryMuscles: [],
            instructions: [],
            category: category,
          );
          expect(exercise.getBasePoints(), 20,
              reason: 'Expected 20 for $level/$category');
        }
      }
    });
  });

  group('Exercise.getPrimaryMusclesDisplay', () {
    test('capitalizes and joins multiple muscles with comma', () {
      final exercise = Exercise(
        id: 'x',
        name: 'X',
        level: 'beginner',
        primaryMuscles: ['chest', 'shoulders'],
        secondaryMuscles: [],
        instructions: [],
        category: 'strength',
      );
      expect(exercise.getPrimaryMusclesDisplay(), 'Chest, Shoulders');
    });

    test('returns Full Body when primaryMuscles is empty', () {
      final exercise = Exercise(
        id: 'x',
        name: 'X',
        level: 'beginner',
        primaryMuscles: [],
        secondaryMuscles: [],
        instructions: [],
        category: 'cardio',
      );
      expect(exercise.getPrimaryMusclesDisplay(), 'Full Body');
    });

    test('capitalizes a single muscle correctly', () {
      final exercise = Exercise(
        id: 'x',
        name: 'X',
        level: 'beginner',
        primaryMuscles: ['abdominals'],
        secondaryMuscles: [],
        instructions: [],
        category: 'core',
      );
      expect(exercise.getPrimaryMusclesDisplay(), 'Abdominals');
    });
  });

  group('Exercise.getEquipmentDisplay', () {
    test('returns Body Weight when equipment is null', () {
      final exercise = Exercise(
        id: 'x',
        name: 'X',
        level: 'beginner',
        primaryMuscles: [],
        secondaryMuscles: [],
        instructions: [],
        category: 'strength',
        equipment: null,
      );
      expect(exercise.getEquipmentDisplay(), 'Body Weight');
    });

    test('returns Body Weight when equipment is empty string', () {
      final exercise = Exercise(
        id: 'x',
        name: 'X',
        level: 'beginner',
        primaryMuscles: [],
        secondaryMuscles: [],
        instructions: [],
        category: 'strength',
        equipment: '',
      );
      expect(exercise.getEquipmentDisplay(), 'Body Weight');
    });

    test('capitalizes equipment name', () {
      final exercise = Exercise(
        id: 'x',
        name: 'X',
        level: 'beginner',
        primaryMuscles: [],
        secondaryMuscles: [],
        instructions: [],
        category: 'strength',
        equipment: 'dumbbell',
      );
      expect(exercise.getEquipmentDisplay(), 'Dumbbell');
    });
  });
}
