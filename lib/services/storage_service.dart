import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_session_model.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box<WorkoutSession> _workoutsBox;
  
  // Keys for SharedPreferences
  static const String _pointsKey = 'total_points';
  static const String _streakKey = 'current_streak';
  static const String _lastActiveKey = 'last_active_date';
  static const String _stepsKey = 'today_steps';
  static const String _stepDateKey = 'step_date';

  /// Initialize storage - call this once at app startup
  static Future<void> initialize() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register Hive adapters (we'll create these next)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WorkoutSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WorkoutExerciseAdapter());
    }
    
    // Open boxes
    _workoutsBox = await Hive.openBox<WorkoutSession>('workouts');
  }

  // ==================== Points ====================
  
  static int getTotalPoints() {
    return _prefs.getInt(_pointsKey) ?? 0;
  }

  static Future<void> setTotalPoints(int points) async {
    await _prefs.setInt(_pointsKey, points);
  }

  static Future<void> addPoints(int points) async {
    final current = getTotalPoints();
    await setTotalPoints(current + points);
  }

  // ==================== Streak ====================
  
  static int getCurrentStreak() {
    return _prefs.getInt(_streakKey) ?? 0;
  }

  static Future<void> setStreak(int streak) async {
    await _prefs.setInt(_streakKey, streak);
  }

  static String? getLastActiveDate() {
    return _prefs.getString(_lastActiveKey);
  }

  static Future<void> setLastActiveDate(String date) async {
    await _prefs.setString(_lastActiveKey, date);
  }

  /// Update streak based on activity
  static Future<void> updateStreak() async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastActive = getLastActiveDate();
    
    if (lastActive == null) {
      // First time
      await setStreak(1);
      await setLastActiveDate(todayStr);
      return;
    }

    if (lastActive == todayStr) {
      // Already active today
      return;
    }

    final lastDate = DateTime.parse(lastActive);
    final daysDiff = today.difference(lastDate).inDays;

    if (daysDiff == 1) {
      // Consecutive day - increase streak
      await setStreak(getCurrentStreak() + 1);
    } else if (daysDiff > 1) {
      // Missed days - reset streak
      await setStreak(1);
    }

    await setLastActiveDate(todayStr);
  }

  // ==================== Steps ====================
  
  static int getTodaySteps() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final savedDate = _prefs.getString(_stepDateKey);
    
    if (savedDate != todayStr) {
      // New day - reset steps
      return 0;
    }
    
    return _prefs.getInt(_stepsKey) ?? 0;
  }

  static Future<void> setTodaySteps(int steps) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    await _prefs.setInt(_stepsKey, steps);
    await _prefs.setString(_stepDateKey, todayStr);
  }

  // ==================== Workouts ====================
  
  static Future<void> saveWorkout(WorkoutSession workout) async {
    await _workoutsBox.put(workout.id, workout);
  }

  static List<WorkoutSession> getAllWorkouts() {
    return _workoutsBox.values.toList();
  }

  static WorkoutSession? getWorkout(String id) {
    return _workoutsBox.get(id);
  }

  static Future<void> deleteWorkout(String id) async {
    await _workoutsBox.delete(id);
  }

  static Future<void> clearAllWorkouts() async {
    await _workoutsBox.clear();
  }

  // ==================== Cleanup ====================
  
  static Future<void> close() async {
    await _workoutsBox.close();
  }

  static Future<void> clearAllData() async {
    await _prefs.clear();
    await _workoutsBox.clear();
  }
}
