/// Model representing a food item from the Kaggle Daily Food & Nutrition Dataset.
/// Source: https://www.kaggle.com/datasets/adilshamim8/daily-food-and-nutrition-dataset
class FoodItem {
  final String name;
  final String category;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double sugars;
  final double sodium;
  final double cholesterol;
  final String mealType; // Breakfast, Lunch, Dinner, Snack, Side
  final double waterIntake;

  FoodItem({
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugars,
    required this.sodium,
    required this.cholesterol,
    required this.mealType,
    required this.waterIntake,
  });

  /// Parse a single CSV row into a FoodItem.
  /// Handles food names that contain commas (e.g. "Milk (2%, 1 cup)").
  factory FoodItem.fromCsvRow(String row) {
    final parts = row.split(',');

    // A valid row has 12 fields. If there are more, the food name contained commas.
    // Join the extra leading parts back into the food name.
    final extraFields = parts.length - 12;
    final String foodName;
    final List<String> fields;

    if (extraFields > 0) {
      foodName = parts.sublist(0, 1 + extraFields).join(',');
      fields = [foodName, ...parts.sublist(1 + extraFields)];
    } else {
      fields = parts;
      foodName = fields[0];
    }

    return FoodItem(
      name: foodName.trim(),
      category: fields[1].trim(),
      calories: double.tryParse(fields[2].trim()) ?? 0,
      protein: double.tryParse(fields[3].trim()) ?? 0,
      carbohydrates: double.tryParse(fields[4].trim()) ?? 0,
      fat: double.tryParse(fields[5].trim()) ?? 0,
      fiber: double.tryParse(fields[6].trim()) ?? 0,
      sugars: double.tryParse(fields[7].trim()) ?? 0,
      sodium: double.tryParse(fields[8].trim()) ?? 0,
      cholesterol: double.tryParse(fields[9].trim()) ?? 0,
      mealType: fields[10].trim(),
      waterIntake: double.tryParse(fields[11].trim()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugars': sugars,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'mealType': mealType,
      'waterIntake': waterIntake,
    };
  }

  /// Total macros in grams (protein + carbs + fat)
  double get totalMacros => protein + carbohydrates + fat;

  /// Primary category (before the slash if multi-category like "Protein/Dairy")
  String get primaryCategory {
    final idx = category.indexOf('/');
    return idx > 0 ? category.substring(0, idx) : category;
  }
}

/// Represents a food entry logged by the user for a meal.
class MealEntry {
  final String foodName;
  final String category;
  final double servings;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double sugars;
  final double sodium;
  final double cholesterol;
  final double waterIntake;
  final String mealType;
  final String timestamp;

  MealEntry({
    required this.foodName,
    required this.category,
    required this.servings,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugars,
    required this.sodium,
    required this.cholesterol,
    required this.waterIntake,
    required this.mealType,
    required this.timestamp,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      foodName: json['foodName'] ?? '',
      category: json['category'] ?? '',
      servings: (json['servings'] ?? 1).toDouble(),
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugars: (json['sugars'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] ?? 0).toDouble(),
      waterIntake: (json['waterIntake'] ?? 0).toDouble(),
      mealType: json['mealType'] ?? 'Snack',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'category': category,
      'servings': servings,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugars': sugars,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'waterIntake': waterIntake,
      'mealType': mealType,
      'timestamp': timestamp,
    };
  }

  /// Create a MealEntry from a FoodItem and a number of servings
  factory MealEntry.fromFood(FoodItem food, double servings, String mealType) {
    return MealEntry(
      foodName: food.name,
      category: food.category,
      servings: servings,
      calories: food.calories,
      protein: food.protein,
      carbohydrates: food.carbohydrates,
      fat: food.fat,
      fiber: food.fiber,
      sugars: food.sugars,
      sodium: food.sodium,
      cholesterol: food.cholesterol,
      waterIntake: food.waterIntake,
      mealType: mealType,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}
