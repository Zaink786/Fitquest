import 'package:hive/hive.dart';
import 'exercise_model.dart';

part 'workout_session_model.g.dart';

/// Represents a single exercise performed in a workout with sets, reps, and points
@HiveType(typeId: 1)
class WorkoutExercise {
  @HiveField(0)
  final String exerciseId;
  
  @HiveField(1)
  final String exerciseName;
  
  @HiveField(2)
  final String exerciseLevel;
  
  @HiveField(3)
  final int sets;
  
  @HiveField(4)
  final int reps;
  
  @HiveField(5)
  final double? weight;
  
  @HiveField(6)
  final int pointsEarned;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseLevel,
    required this.sets,
    required this.reps,
    this.weight,
    required this.pointsEarned,
  });

  /// Create from Exercise object
  factory WorkoutExercise.fromExercise({
    required Exercise exercise,
    required int sets,
    required int reps,
    double? weight,
  }) {
    final points = calculatePoints(
      exercise: exercise,
      sets: sets,
      reps: reps,
      weight: weight,
    );

    return WorkoutExercise(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      exerciseLevel: exercise.level,
      sets: sets,
      reps: reps,
      weight: weight,
      pointsEarned: points,
    );
  }

  /// Flat 20 points per workout logged
  static int calculatePoints({
    required Exercise exercise,
    required int sets,
    required int reps,
    double? weight,
  }) {
    return 20;
  }
}

/// Represents a complete workout session with multiple exercises
@HiveType(typeId: 0)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final DateTime date;
  
  @HiveField(3)
  final List<WorkoutExercise> exercises;
  
  @HiveField(4)
  final int totalPoints;
  
  @HiveField(5)
  final int? durationSeconds;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
    required this.totalPoints,
    this.durationSeconds,
  });

  /// Calculate total points from all exercises in the session
  static int calculateTotalPoints(List<WorkoutExercise> exercises) {
    return exercises.fold(0, (sum, ex) => sum + ex.pointsEarned);
  }

  /// Get formatted duration string
  String getDurationDisplay() {
    if (durationSeconds == null) return 'Not tracked';
    final minutes = durationSeconds! ~/ 60;
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
}
