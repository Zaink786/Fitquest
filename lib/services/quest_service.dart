import '../models/quest_model.dart';
import '../models/workout_session_model.dart';
import 'storage_service.dart';

/// Result of processing a completed workout for quest progression.
class QuestResult {
  final int questPointsAwarded;
  final int prCount;
  final QuestWorld? newWorldUnlocked;

  const QuestResult({
    required this.questPointsAwarded,
    required this.prCount,
    this.newWorldUnlocked,
  });
}

/// Handles progressive overload detection and quest point awarding.
class QuestService {
  static const int pointsPerPR = 50;

  /// Process a completed workout — detect PRs and award quest points.

  /// [StorageService.getLastSessionForExercise] returns the previous session.
  static Future<QuestResult> processWorkoutCompletion(
    List<WorkoutExercise> exercises,
  ) async {
    final worldBefore = getCurrentWorld(StorageService.getQuestPoints());
    int prCount = 0;

    for (final exercise in exercises) {
      if (_isPersonalRecord(exercise)) {
        prCount++;
      }
    }

    final questPointsAwarded = prCount * pointsPerPR;

    if (questPointsAwarded > 0) {
      await StorageService.addQuestPoints(questPointsAwarded);
    }

    // Check if we crossed into a new world
    final worldAfter = getCurrentWorld(StorageService.getQuestPoints());
    final newWorld = worldAfter.id > worldBefore.id ? worldAfter : null;

    return QuestResult(
      questPointsAwarded: questPointsAwarded,
      prCount: prCount,
      newWorldUnlocked: newWorld,
    );
  }

  /// Check if an exercise beats the previous session's weight or reps.
  static bool _isPersonalRecord(WorkoutExercise exercise) {
    final lastSession = StorageService.getLastSessionForExercise(
      exercise.exerciseId,
    );
    if (lastSession == null) return false; // first time — no PR to beat

    final WorkoutExercise? lastExercise = _findExerciseInSession(
      lastSession,
      exercise.exerciseId,
    );
    if (lastExercise == null) return false;

    // PR if weight increased
    if (exercise.weight != null &&
        lastExercise.weight != null &&
        exercise.weight! > lastExercise.weight!) {
      return true;
    }

    // PR if reps increased (at same or higher weight)
    if (exercise.reps > lastExercise.reps) {
      // For weighted exercises, only count reps PR if weight didn't decrease
      if (exercise.weight != null && lastExercise.weight != null) {
        return exercise.weight! >= lastExercise.weight!;
      }
      // For bodyweight exercises, reps increase is always a PR
      return true;
    }

    return false;
  }

  // Find a specific exercise within a workout session.
  static WorkoutExercise? _findExerciseInSession(
    WorkoutSession session,
    String exerciseId,
  ) {
    for (final ex in session.exercises) {
      if (ex.exerciseId == exerciseId) return ex;
    }
    return null;
  }
}
