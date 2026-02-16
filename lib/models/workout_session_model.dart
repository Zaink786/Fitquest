import 'exercise_model.dart';

/// Represents a single exercise performed in a workout with sets, reps, and points
class WorkoutExercise {
  final Exercise exercise;
  final int sets;
  final int reps;
  final double? weight; // Optional weight in kg/lbs
  final int pointsEarned;

  WorkoutExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    this.weight,
    required this.pointsEarned,
  });

  /// Calculate points for this exercise based on difficulty and volume
  static int calculatePoints({
    required Exercise exercise,
    required int sets,
    required int reps,
    double? weight,
  }) {
    int basePoints = exercise.getBasePoints();
    int totalReps = sets * reps;
    
    // Base calculation: basePoints * sets
    int points = basePoints * sets;
    
    // Bonus for high volume (more than 50 total reps)
    if (totalReps > 50) {
      points = (points * 1.2).round();
    }
    
    // Bonus for using weights
    if (weight != null && weight > 0) {
      points = (points * 1.1).round();
    }
    
    return points;
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'pointsEarned': pointsEarned,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exercise: Exercise.fromJson(json['exercise']),
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      weight: json['weight'],
      pointsEarned: json['pointsEarned'] ?? 0,
    );
  }
}

/// Represents a complete workout session with multiple exercises
class WorkoutSession {
  final String id;
  final String name;
  final DateTime date;
  final List<WorkoutExercise> exercises;
  final int totalPoints;
  final Duration? duration;
  final String? notes;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
    required this.totalPoints,
    this.duration,
    this.notes,
  });

  /// Calculate total points from all exercises in the session
  static int calculateTotalPoints(List<WorkoutExercise> exercises) {
    return exercises.fold(0, (sum, ex) => sum + ex.pointsEarned);
  }

  /// Get formatted duration string
  String getDurationDisplay() {
    if (duration == null) return 'Not tracked';
    final minutes = duration!.inMinutes;
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'totalPoints': totalPoints,
      'duration': duration?.inSeconds,
      'notes': notes,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      date: DateTime.parse(json['date']),
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e))
          .toList(),
      totalPoints: json['totalPoints'] ?? 0,
      duration: json['duration'] != null 
          ? Duration(seconds: json['duration']) 
          : null,
      notes: json['notes'],
    );
  }
}
