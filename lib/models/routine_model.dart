/// A single exercise entry inside a saved routine.
/// Sets, reps and weight are mutable so the user can edit them in-place.
class RoutineExercise {
  final String exerciseId;
  final String exerciseName;
  int sets;
  int reps;
  double? weight; // kg, optional

  RoutineExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = 3,
    this.reps = 10,
    this.weight,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets,
        'reps': reps,
        'weight': weight,
      };

  factory RoutineExercise.fromJson(Map<String, dynamic> json) =>
      RoutineExercise(
        exerciseId: json['exerciseId'] as String? ?? '',
        exerciseName: json['exerciseName'] as String? ?? '',
        sets: json['sets'] as int? ?? 3,
        reps: json['reps'] as int? ?? 10,
        weight: (json['weight'] as num?)?.toDouble(),
      );
}

/// A named, saved workout plan containing one or more exercises.
class Routine {
  final String id;
  String name;
  List<RoutineExercise> exercises;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
  });

  /// Total sets across all exercises in this routine.
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) =>
                RoutineExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );
}
