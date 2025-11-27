//basic points calculation service
class PointsService {
  /// 1 point per 100 steps
  static int calculateStepPoints(int steps) {
    return steps ~/ 100;
  }

  /// for workout-based points later
  static int calculateWorkoutPoints({
    required int basePoints,
    double multiplier = 1.0,
  }) {
    return (basePoints * multiplier).round();
  }
}
