import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise_model.dart';

class ExerciseService {
  List<Exercise>? _cachedExercises;

  /// Load all exercises from the JSON asset
  Future<List<Exercise>> loadExercises() async {
    if (_cachedExercises != null) return _cachedExercises!;

    try {
      final String response = await rootBundle.loadString('assets/data/exercises.json');
      final Map<String, dynamic> data = json.decode(response);
      
      // The free-exercise-db has exercises in an "exercises" array
      final List<dynamic> exercisesJson = data['exercises'] ?? [];
      
      _cachedExercises = exercisesJson
          .map((json) => Exercise.fromJson(json))
          .toList();

      return _cachedExercises!;
    } catch (e) {
      print('Error loading exercises: $e');
      throw Exception('Failed to load exercise database');
    }
  }

  /// Get exercises by category (strength, cardio, stretching, etc.)
  Future<List<Exercise>> getExercisesByCategory(String category) async {
    final exercises = await loadExercises();
    return exercises
        .where((e) => e.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get exercises by equipment (barbell, dumbbell, body only, etc.)
  Future<List<Exercise>> getExercisesByEquipment(String equipment) async {
    final exercises = await loadExercises();
    if (equipment.toLowerCase() == 'body weight' || equipment.toLowerCase() == 'bodyweight') {
      return exercises
          .where((e) => e.equipment == null || 
                       e.equipment!.isEmpty || 
                       e.equipment!.toLowerCase() == 'body only')
          .toList();
    }
    return exercises
        .where((e) => e.equipment != null && 
                     e.equipment!.toLowerCase().contains(equipment.toLowerCase()))
        .toList();
  }

  /// Get exercises by muscle group (primary or secondary)
  Future<List<Exercise>> getExercisesByMuscle(String muscle) async {
    final exercises = await loadExercises();
    final lowerMuscle = muscle.toLowerCase();
    return exercises.where((e) => 
      e.primaryMuscles.any((m) => m.toLowerCase().contains(lowerMuscle)) ||
      e.secondaryMuscles.any((m) => m.toLowerCase().contains(lowerMuscle))
    ).toList();
  }

  /// Get exercises by difficulty level (beginner, intermediate, expert)
  Future<List<Exercise>> getExercisesByLevel(String level) async {
    final exercises = await loadExercises();
    return exercises
        .where((e) => e.level.toLowerCase() == level.toLowerCase())
        .toList();
  }

  /// Search exercises by name
  Future<List<Exercise>> searchExercises(String query) async {
    final exercises = await loadExercises();
    final lowerQuery = query.toLowerCase();
    return exercises
        .where((e) => e.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get a random workout routine
  Future<List<Exercise>> getRandomWorkout({
    int count = 5,
    String? category,
    String? level,
    String? equipment,
  }) async {
    var exercises = await loadExercises();
    
    // Filter by category if provided
    if (category != null) {
      exercises = exercises
          .where((e) => e.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    
    // Filter by level if provided
    if (level != null) {
      exercises = exercises
          .where((e) => e.level.toLowerCase() == level.toLowerCase())
          .toList();
    }

    // Filter by equipment if provided
    if (equipment != null) {
      if (equipment.toLowerCase() == 'body weight' || equipment.toLowerCase() == 'bodyweight') {
        exercises = exercises
            .where((e) => e.equipment == null || 
                         e.equipment!.isEmpty || 
                         e.equipment!.toLowerCase() == 'body only')
            .toList();
      } else {
        exercises = exercises
            .where((e) => e.equipment != null && 
                         e.equipment!.toLowerCase().contains(equipment.toLowerCase()))
            .toList();
      }
    }
    
    // Shuffle and take
    exercises.shuffle();
    return exercises.take(count > exercises.length ? exercises.length : count).toList();
  }

  /// Get all unique categories from the database
  Future<List<String>> getCategories() async {
    final exercises = await loadExercises();
    final categories = exercises.map((e) => e.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Get all unique equipment types from the database
  Future<List<String>> getEquipmentTypes() async {
    final exercises = await loadExercises();
    final equipment = exercises
        .map((e) => e.equipment)
        .where((eq) => eq != null && eq.isNotEmpty)
        .toSet()
        .toList();
    equipment.sort();
    return equipment;
  }

  /// Get all unique muscle groups from the database
  Future<List<String>> getMuscleGroups() async {
    final exercises = await loadExercises();
    final muscles = <String>{};
    for (var exercise in exercises) {
      muscles.addAll(exercise.primaryMuscles);
      muscles.addAll(exercise.secondaryMuscles);
    }
    final muscleList = muscles.toList();
    muscleList.sort();
    return muscleList;
  }

  /// Get statistics about the exercise database
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final exercises = await loadExercises();
    final categories = await getCategories();
    final equipment = await getEquipmentTypes();
    final muscles = await getMuscleGroups();

    return {
      'totalExercises': exercises.length,
      'categories': categories.length,
      'equipmentTypes': equipment.length,
      'muscleGroups': muscles.length,
      'beginnerExercises': exercises.where((e) => e.level.toLowerCase() == 'beginner').length,
      'intermediateExercises': exercises.where((e) => e.level.toLowerCase() == 'intermediate').length,
      'expertExercises': exercises.where((e) => e.level.toLowerCase() == 'expert').length,
    };
  }
}
