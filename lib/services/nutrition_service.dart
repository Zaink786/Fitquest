import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_model.dart';

class NutritionService {
  List<FoodItem>? _cachedFoods;

  /// Load all food items from the Kaggle CSV asset.
  Future<List<FoodItem>> loadFoods() async {
    if (_cachedFoods != null) return _cachedFoods!;

    try {
      final String csv = await rootBundle.loadString(
        'assets/data/daily_food_nutrition_dataset.csv',
      );

      _cachedFoods = await Isolate.run(() => _parseCsv(csv));

      return _cachedFoods!;
    } catch (e) {
      throw Exception('Failed to load food database: $e');
    }
  }

  static List<FoodItem> _parseCsv(String csv) {
    final lines = csv.split('\n');
    final List<FoodItem> foods = [];
    final seen = <String>{};

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      try {
        final food = FoodItem.fromCsvRow(line);
        if (food.name.isNotEmpty && food.calories > 0 && seen.add(food.name)) {
          foods.add(food);
        }
      } catch (_) {
        continue;
      }
    }

    foods.sort((a, b) => a.name.compareTo(b.name));
    return foods;
  }

  /// Search foods by name
  Future<List<FoodItem>> searchFoods(String query) async {
    final foods = await loadFoods();
    final lowerQuery = query.toLowerCase();
    return foods
        .where((f) => f.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get foods by primary category
  Future<List<FoodItem>> getFoodsByCategory(String category) async {
    final foods = await loadFoods();
    if (category == 'All') return foods;
    return foods
        .where((f) => f.category.toLowerCase().contains(category.toLowerCase()))
        .toList();
  }

  /// Get all unique primary categories
  Future<List<String>> getCategories() async {
    final foods = await loadFoods();
    final categories = foods.map((f) => f.primaryCategory).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Get database stats
  Future<Map<String, int>> getDatabaseStats() async {
    final foods = await loadFoods();
    final categories = foods.map((f) => f.primaryCategory).toSet();
    return {'totalFoods': foods.length, 'categories': categories.length};
  }

  // ─── Custom Foods ───

  static const _customFoodsKey = 'user_custom_foods';

  static Future<List<FoodItem>> getCustomFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_customFoodsKey) ?? [];
    return raw.map((s) {
      final map = json.decode(s) as Map<String, dynamic>;
      return FoodItem(
        name: map['name'] as String,
        category: 'Custom',
        calories: (map['calories'] as num).toDouble(),
        protein: (map['protein'] as num? ?? 0).toDouble(),
        carbohydrates: (map['carbohydrates'] as num? ?? 0).toDouble(),
        fat: (map['fat'] as num? ?? 0).toDouble(),
        fiber: 0, sugars: 0, sodium: 0, cholesterol: 0,
        mealType: '', waterIntake: 0,
      );
    }).toList();
  }

  static Future<void> addCustomFood(
    String name,
    double calories, {
    double protein = 0,
    double carbohydrates = 0,
    double fat = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_customFoodsKey) ?? [];
    existing.add(json.encode({
      'name': name.trim(),
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
    }));
    await prefs.setStringList(_customFoodsKey, existing);
  }

  // ─── Meal Logging (SharedPreferences) ───

  static const _mealsKey = 'logged_meals';

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Log a meal entry
  static Future<void> logMeal(MealEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_mealsKey) ?? [];
    existing.add(json.encode(entry.toJson()));
    await prefs.setStringList(_mealsKey, existing);
  }

  /// Get all logged meals
  static Future<List<MealEntry>> getAllMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_mealsKey) ?? [];
    return raw
        .map((s) {
          try {
            return MealEntry.fromJson(json.decode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<MealEntry>()
        .toList();
  }

  /// Get today's meals
  static Future<List<MealEntry>> getTodaysMeals() async {
    final all = await getAllMeals();
    final today = _todayKey();
    return all.where((m) {
      try {
        final d = DateTime.parse(m.timestamp);
        final key =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        return key == today;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Get today's macro totals
  static Future<Map<String, double>> getTodaysMacros() async {
    final meals = await getTodaysMeals();
    double totalCal = 0, totalP = 0, totalC = 0, totalF = 0;
    double totalFiber = 0, totalSugars = 0, totalSodium = 0;
    double totalCholesterol = 0, totalWater = 0;

    for (final m in meals) {
      totalCal += m.calories * m.servings;
      totalP += m.protein * m.servings;
      totalC += m.carbohydrates * m.servings;
      totalF += m.fat * m.servings;
      totalFiber += m.fiber * m.servings;
      totalSugars += m.sugars * m.servings;
      totalSodium += m.sodium * m.servings;
      totalCholesterol += m.cholesterol * m.servings;
      totalWater += m.waterIntake * m.servings;
    }

    return {
      'calories': totalCal,
      'protein': totalP,
      'carbohydrates': totalC,
      'fat': totalF,
      'fiber': totalFiber,
      'sugars': totalSugars,
      'sodium': totalSodium,
      'cholesterol': totalCholesterol,
      'water': totalWater,
    };
  }

  /// Clear all meal logs
  static Future<void> clearMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mealsKey);
  }

  // ─── Calorie Goal ───

  static const _calorieGoalKey = 'calorie_goal';

  static Future<double> getCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_calorieGoalKey) ?? 2000;
  }

  static Future<void> saveCalorieGoal(double goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_calorieGoalKey, goal);
  }

  // ─── Macro Goals ───

  static Future<Map<String, double>> getMacroGoals() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'protein': prefs.getDouble('macro_goal_protein') ?? 150,
      'carbs': prefs.getDouble('macro_goal_carbs') ?? 250,
      'fat': prefs.getDouble('macro_goal_fat') ?? 65,
      'fiber': prefs.getDouble('macro_goal_fiber') ?? 30,
    };
  }

  static Future<void> saveMacroGoals(Map<String, double> goals) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in goals.entries) {
      await prefs.setDouble('macro_goal_${e.key}', e.value);
    }
  }
}
