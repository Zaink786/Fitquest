/// In-memory models for an active (in-progress) workout session.
/// These are ephemeral — not persisted to Hive.

class ActiveSet {
  double? kg;
  int reps;
  bool isDone;

  ActiveSet({this.kg, this.reps = 10, this.isDone = false});
}

class ActiveExerciseEntry {
  final String exerciseId;
  final String exerciseName;
  List<ActiveSet> sets;

  ActiveExerciseEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });

  int get completedSets => sets.where((s) => s.isDone).length;
  bool get isFullyComplete => sets.isNotEmpty && completedSets == sets.length;
}
