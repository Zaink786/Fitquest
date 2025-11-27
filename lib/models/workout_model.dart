// Model for a workout session
class Workout {
  final String id;
  final String name;
  final String type; // e.g. 'Run', 'Gym', 'Walk'
  final DateTime date;
  final int durationMinutes;
  final int pointsEarned;

  Workout({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.durationMinutes,
    required this.pointsEarned,
  });
}
