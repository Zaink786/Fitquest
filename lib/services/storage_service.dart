import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout_session_model.dart';
import '../models/level_model.dart';
import '../models/achievement_model.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box<WorkoutSession> _workoutsBox;
  static String _userPrefix = '';
  static String? _currentWorkoutBoxName;

  static const String _currentUserKey = 'auth_current_user';

  // Keys for SharedPreferences
  static const String _pointsKeyBase = 'total_points';
  static const String _streakKeyBase = 'current_streak';
  static const String _lastActiveKeyBase = 'last_active_date';
  static const String _stepsKeyBase = 'today_steps';
  static const String _stepDateKeyBase = 'step_date';
  static const String _dailyPointsKeyBase = 'daily_points';
  static const String _dailyPointsDateKeyBase = 'daily_points_date';
  static const String _unlockedAchievementsKeyBase = 'unlocked_achievements';
  static const String _dailyAchievementsDateKeyBase = 'daily_achievements_date';
  static const String _calorieGoalMetDateKeyBase = 'calorie_goal_met_date';
  static const String _questPointsKeyBase = 'quest_points';
  static const String _hasSeenOnboardingKeyBase = 'has_seen_onboarding';
  static const String _pendingWelcomeBackKeyBase = 'pending_welcome_back';
  static const String _pendingOnboardingFlowKeyBase = 'pending_onboarding_flow';
  static const String _hasSeenNutritionWarningKeyBase =
      'has_seen_nutrition_warning';
  static const String _pendingOnboardingTipsKeyBase = 'pending_onboarding_tips';
  static const String _hasSeenWelcomeTipKeyBase = 'has_seen_welcome_tip';
  static const String _hasSeenCalorieTipKeyBase = 'has_seen_calorie_tip';

  static String _withUserPrefix(String key) => '$_userPrefix$key';

  static String get _pointsKey => _withUserPrefix(_pointsKeyBase);
  static String get _streakKey => _withUserPrefix(_streakKeyBase);
  static String get _lastActiveKey => _withUserPrefix(_lastActiveKeyBase);
  static String get _stepsKey => _withUserPrefix(_stepsKeyBase);
  static String get _stepDateKey => _withUserPrefix(_stepDateKeyBase);
  static String get _dailyPointsKey => _withUserPrefix(_dailyPointsKeyBase);
  static String get _dailyPointsDateKey =>
      _withUserPrefix(_dailyPointsDateKeyBase);
  static String get _unlockedAchievementsKey =>
      _withUserPrefix(_unlockedAchievementsKeyBase);
  static String get _dailyAchievementsDateKey =>
      _withUserPrefix(_dailyAchievementsDateKeyBase);
  static String get _calorieGoalMetDateKey =>
      _withUserPrefix(_calorieGoalMetDateKeyBase);
  static String get _questPointsKey => _withUserPrefix(_questPointsKeyBase);
  static String get _hasSeenOnboardingKey =>
      _withUserPrefix(_hasSeenOnboardingKeyBase);
  static String get _pendingWelcomeBackKey =>
      _withUserPrefix(_pendingWelcomeBackKeyBase);
  static String get _pendingOnboardingFlowKey =>
      _withUserPrefix(_pendingOnboardingFlowKeyBase);
  static String get _hasSeenNutritionWarningKey =>
      _withUserPrefix(_hasSeenNutritionWarningKeyBase);
  static String get _pendingOnboardingTipsKey =>
      _withUserPrefix(_pendingOnboardingTipsKeyBase);
  static String get _hasSeenWelcomeTipKey =>
      _withUserPrefix(_hasSeenWelcomeTipKeyBase);
  static String get _hasSeenCalorieTipKey =>
      _withUserPrefix(_hasSeenCalorieTipKeyBase);

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static String _boxNameForEmail(String email) {
    final normalized = _normalizeEmail(email);
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'workouts_$safe';
  }

  static Future<void> _openWorkoutsBox(String boxName) async {
    if (_currentWorkoutBoxName == boxName && Hive.isBoxOpen(boxName)) {
      _workoutsBox = Hive.box<WorkoutSession>(boxName);
      return;
    }

    if (_currentWorkoutBoxName != null &&
        Hive.isBoxOpen(_currentWorkoutBoxName!)) {
      await Hive.box<WorkoutSession>(_currentWorkoutBoxName!).close();
    }

    _workoutsBox = await Hive.openBox<WorkoutSession>(boxName);
    _currentWorkoutBoxName = boxName;
  }

  static void setCurrentUser(String email) {
    _userPrefix = '${_normalizeEmail(email)}_';
  }

  static Future<void> openUserBox(String email) async {
    setCurrentUser(email);
    await _openWorkoutsBox(_boxNameForEmail(email));
  }

  static Future<void> switchToAnonymousStorage() async {
    clearCurrentUser();
    await _openWorkoutsBox('workouts');
  }

  static void clearCurrentUser() {
    _userPrefix = '';
  }

  static Future<void> initialize() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize Hive
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WorkoutSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WorkoutExerciseAdapter());
    }

    final currentUser = _prefs.getString(_currentUserKey);
    if (currentUser != null && currentUser.trim().isNotEmpty) {
      await openUserBox(currentUser);
    } else {
      await switchToAnonymousStorage();
    }
  }

  // Points

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

  // Level System

  /// Get the user's current level info based on total points.
  static LevelInfo getLevelInfo() {
    return LevelSystem.fromTotalXp(getTotalPoints());
  }

  // Streak

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
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
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
      final newStreak = getCurrentStreak() + 1;
      await setStreak(newStreak);
      // +10 XP for maintaining a streak
      await addPoints(10);
      await addDailyPoints(10);
    } else if (daysDiff > 1) {
      // Missed days - reset streak
      await setStreak(1);
    }

    await setLastActiveDate(todayStr);
  }

  /// Called on app open to reset the streak if the user missed days.
  static Future<bool> validateStreak() async {
    final lastActive = getLastActiveDate();
    if (lastActive == null) return false;

    final today = DateTime.now();
    final lastDate = DateTime.parse(lastActive);
    final daysDiff = today.difference(lastDate).inDays;

    if (daysDiff > 1 && getCurrentStreak() > 0) {
      await setStreak(0);
      return true;
    }
    return false;
  }

  //  Steps

  static int getTodaySteps() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final savedDate = _prefs.getString(_stepDateKey);

    if (savedDate != todayStr) {
      // New day - reset steps
      return 0;
    }

    return _prefs.getInt(_stepsKey) ?? 0;
  }

  static Future<void> setTodaySteps(int steps) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _prefs.setInt(_stepsKey, steps);
    await _prefs.setString(_stepDateKey, todayStr);
  }

  //  Workouts

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

  /// Returns the most recent [WorkoutSession] that contains an exercise
  /// Returns null if no history exists for this exercise.
  static WorkoutSession? getLastSessionForExercise(String exerciseId) {
    final sessions = getAllWorkouts()..sort((a, b) => b.date.compareTo(a.date));
    for (final session in sessions) {
      if (session.exercises.any((ex) => ex.exerciseId == exerciseId)) {
        return session;
      }
    }
    return null;
  }

  // Daily Points

  static int getDailyPoints() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final savedDate = _prefs.getString(_dailyPointsDateKey);

    if (savedDate != todayStr) {
      // New day - reset daily points
      return 0;
    }

    return _prefs.getInt(_dailyPointsKey) ?? 0;
  }

  static Future<void> addDailyPoints(int points) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final savedDate = _prefs.getString(_dailyPointsDateKey);

    int currentDailyPoints = 0;
    if (savedDate == todayStr) {
      currentDailyPoints = _prefs.getInt(_dailyPointsKey) ?? 0;
    }

    final newDailyPoints = currentDailyPoints + points;
    await _prefs.setInt(_dailyPointsKey, newDailyPoints);
    await _prefs.setString(_dailyPointsDateKey, todayStr);

    // Check for 100 points achievement
    await _checkDailyPointsAchievement(newDailyPoints);
  }

  static Future<void> _checkDailyPointsAchievement(int dailyPoints) async {
    if (dailyPoints >= 100 && !isAchievementUnlocked('first_100_points')) {
      await unlockAchievement('first_100_points');
    }
  }

  // Achievements

  static List<String> getUnlockedAchievements() {
    return _prefs.getStringList(_unlockedAchievementsKey) ?? [];
  }

  static bool isAchievementUnlocked(String achievementId) {
    final unlocked = getUnlockedAchievements();
    return unlocked.contains(achievementId);
  }

  static Future<void> unlockAchievement(String achievementId) async {
    final unlocked = getUnlockedAchievements();
    if (!unlocked.contains(achievementId)) {
      unlocked.add(achievementId);
      await _prefs.setStringList(_unlockedAchievementsKey, unlocked);

      // Find the achievement to get its reward
      final achievement = Achievements.allAchievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => Achievements.firstWorkout, // Fallback
      );

      final reward = achievement.xpReward > 0
          ? achievement.xpReward
          : 30; // 30 is default

      await addPoints(reward);
      await addDailyPoints(reward);
    }
  }

  static Future<void> resetDailyAchievementsIfNeeded() =>
      _checkDailyAchievementsReset();

  static Future<void> _checkDailyAchievementsReset() async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final lastResetDate = _prefs.getString(_dailyAchievementsDateKey);

    if (lastResetDate != todayStr) {
      // New day - reset daily achievements from unlocked list
      final unlocked = getUnlockedAchievements();
      final dailyIds = Achievements.allAchievements
          .where((a) => a.isDaily)
          .map((a) => a.id)
          .toList();

      final filtered = unlocked.where((id) => !dailyIds.contains(id)).toList();
      await _prefs.setStringList(_unlockedAchievementsKey, filtered);
      await _prefs.setString(_dailyAchievementsDateKey, todayStr);
    }
  }

  static Future<void> checkDailyWorkout() async {
    await _checkDailyAchievementsReset();
    if (!isAchievementUnlocked('daily_workout')) {
      await unlockAchievement('daily_workout');
    }
  }

  static Future<void> checkDailyNutrition(int mealCount) async {
    await _checkDailyAchievementsReset();
    if (mealCount >= 3 && !isAchievementUnlocked('daily_nutrition')) {
      await unlockAchievement('daily_nutrition');
    }
  }

  static Future<void> checkDailySteps(int steps) async {
    await _checkDailyAchievementsReset();
    if (steps >= 5000 && !isAchievementUnlocked('daily_steps')) {
      await unlockAchievement('daily_steps');
    }
  }

  static Future<void> checkFirstWorkoutAchievement() async {
    if (!isAchievementUnlocked('first_workout')) {
      await unlockAchievement('first_workout');
    }
  }

  static Future<void> checkStreakAchievement(int streak) async {
    if (streak >= 3 && !isAchievementUnlocked('consistency_starter')) {
      await unlockAchievement('consistency_starter');
    }
  }

  static Future<void> checkPrAchievement(WorkoutSession currentSession) async {
    if (isAchievementUnlocked('first_pr')) return;

    for (final exercise in currentSession.exercises) {
      if (exercise.weight == null) continue;

      final previousSessions = getAllWorkouts()
          .where((session) => session.id != currentSession.id)
          .toList();

      double? maxPreviousWeight;
      for (final session in previousSessions) {
        for (final prevExercise in session.exercises) {
          if (prevExercise.exerciseId == exercise.exerciseId &&
              prevExercise.weight != null) {
            maxPreviousWeight = maxPreviousWeight == null
                ? prevExercise.weight
                : (prevExercise.weight! > maxPreviousWeight
                    ? prevExercise.weight
                    : maxPreviousWeight);
          }
        }
      }

      if (maxPreviousWeight == null || exercise.weight! > maxPreviousWeight) {
        await unlockAchievement('first_pr');
        return;
      }
    }
  }

  //  Calorie Goal

  /// Returns true if the calorie goal bonus was already awarded today.
  static bool isCalorieGoalMetToday() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _prefs.getString(_calorieGoalMetDateKey) == todayStr;
  }

  /// Mark calorie goal as met today and award +20 XP.
  static Future<void> awardCalorieGoalBonus() async {
    if (isCalorieGoalMetToday()) return; // already awarded today
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await _prefs.setString(_calorieGoalMetDateKey, todayStr);
    await addPoints(20);
    await addDailyPoints(20);
  }

  //  Quest Points

  static int getQuestPoints() {
    return _prefs.getInt(_questPointsKey) ?? 0;
  }

  static Future<void> setQuestPoints(int points) async {
    await _prefs.setInt(_questPointsKey, points);
  }

  static Future<void> addQuestPoints(int points) async {
    final current = getQuestPoints();
    await setQuestPoints(current + points);
  }

  // Welcome-back banner

  static bool hasPendingWelcomeBack() {
    return _prefs.getBool(_pendingWelcomeBackKey) ?? false;
  }

  static Future<void> setPendingWelcomeBack() async {
    await _prefs.setBool(_pendingWelcomeBackKey, true);
  }

  static Future<void> clearPendingWelcomeBack() async {
    await _prefs.remove(_pendingWelcomeBackKey);
  }

  // First-login onboarding flow

  static bool hasPendingOnboardingFlow() {
    return _prefs.getBool(_pendingOnboardingFlowKey) ?? false;
  }

  static Future<void> markOnboardingFlowPending() async {
    await _prefs.setBool(_pendingOnboardingFlowKey, true);
  }

  static Future<void> clearOnboardingFlow() async {
    await _prefs.remove(_pendingOnboardingFlowKey);
  }

  // Onboarding

  static bool hasSeenOnboarding() {
    return _prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  static Future<void> setHasSeenOnboarding() async {
    await _prefs.setBool(_hasSeenOnboardingKey, true);
  }

  // Nutrition warning

  static bool hasSeenNutritionWarning() {
    return _prefs.getBool(_hasSeenNutritionWarningKey) ?? false;
  }

  static Future<void> setHasSeenNutritionWarning() async {
    await _prefs.setBool(_hasSeenNutritionWarningKey, true);
  }

  // Onboarding tips (shown on first login)

  static bool hasPendingOnboardingTips() {
    return _prefs.getBool(_pendingOnboardingTipsKey) ?? false;
  }

  static Future<void> markOnboardingTipsPending() async {
    await _prefs.setBool(_pendingOnboardingTipsKey, true);
  }

  static bool hasSeenWelcomeTip() {
    return _prefs.getBool(_hasSeenWelcomeTipKey) ?? false;
  }

  static Future<void> setHasSeenWelcomeTip() async {
    await _prefs.setBool(_hasSeenWelcomeTipKey, true);
  }

  static bool hasSeenCalorieTip() {
    return _prefs.getBool(_hasSeenCalorieTipKey) ?? false;
  }

  static Future<void> setHasSeenCalorieTip() async {
    await _prefs.setBool(_hasSeenCalorieTipKey, true);
  }

  //  Cleanup

  static Future<void> close() async {
    await _workoutsBox.close();
  }

  static Future<void> clearAllData() async {
    await _prefs.clear();
    await _workoutsBox.clear();
  }
}
