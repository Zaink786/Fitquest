import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_model.dart';

/// Persists saved routines as JSON in SharedPreferences.
class RoutineService {
  static const String _key = 'saved_routines';

  /// Load all saved routines, sorted by creation date (oldest first).
  static Future<List<Routine>> getRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) {
          try {
            return Routine.fromJson(json.decode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Routine>()
        .toList();
  }

  /// Add a new routine or replace an existing one (matched by id).
  static Future<void> saveRoutine(Routine routine) async {
    final routines = await getRoutines();
    final idx = routines.indexWhere((r) => r.id == routine.id);
    if (idx >= 0) {
      routines[idx] = routine;
    } else {
      routines.add(routine);
    }
    await _persist(routines);
  }

  /// Permanently remove a routine by id.
  static Future<void> deleteRoutine(String id) async {
    final routines = await getRoutines();
    routines.removeWhere((r) => r.id == id);
    await _persist(routines);
  }

  static Future<void> _persist(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      routines.map((r) => json.encode(r.toJson())).toList(),
    );
  }
}
