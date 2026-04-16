import 'package:flutter_test/flutter_test.dart';
import 'package:fitquest/models/food_model.dart';

void main() {
  group('FoodItem.fromCsvRow', () {
    test('parses a standard 12-field CSV row correctly', () {
      const row =
          'Apple,Fruit,95,0.5,25,0.3,4.4,18.9,1.8,0,Snack,150';
      final item = FoodItem.fromCsvRow(row);

      expect(item.name, 'Apple');
      expect(item.category, 'Fruit');
      expect(item.calories, closeTo(95, 0.01));
      expect(item.protein, closeTo(0.5, 0.01));
      expect(item.carbohydrates, closeTo(25, 0.01));
      expect(item.fat, closeTo(0.3, 0.01));
      expect(item.fiber, closeTo(4.4, 0.01));
      expect(item.sugars, closeTo(18.9, 0.01));
      expect(item.sodium, closeTo(1.8, 0.01));
      expect(item.cholesterol, closeTo(0, 0.01));
      expect(item.mealType, 'Snack');
      expect(item.waterIntake, closeTo(150, 0.01));
    });

    test('handles food name containing a comma', () {
      // "Milk (2%, 1 cup)" has a comma inside the name — 13 fields total
      const row = 'Milk (2%,1 cup),Dairy,122,8,12,4.8,0,12,107,20,Breakfast,244';
      final item = FoodItem.fromCsvRow(row);

      expect(item.name, 'Milk (2%,1 cup)');
      expect(item.category, 'Dairy');
      expect(item.calories, closeTo(122, 0.01));
      expect(item.mealType, 'Breakfast');
    });

    test('defaults to 0 for unparseable numeric fields', () {
      const row = 'Test Food,Misc,bad,bad,bad,bad,bad,bad,bad,bad,Lunch,bad';
      final item = FoodItem.fromCsvRow(row);

      expect(item.calories, 0.0);
      expect(item.protein, 0.0);
      expect(item.waterIntake, 0.0);
    });

    test('trims whitespace from all fields', () {
      const row = ' Banana , Fruit , 89 , 1.1 , 23 , 0.3 , 2.6 , 12 , 1 , 0 , Snack , 75 ';
      final item = FoodItem.fromCsvRow(row);

      expect(item.name, 'Banana');
      expect(item.category, 'Fruit');
      expect(item.mealType, 'Snack');
    });
  });

  group('FoodItem computed properties', () {
    FoodItem makeFood({
      double protein = 10,
      double carbohydrates = 20,
      double fat = 5,
      String category = 'Protein',
    }) {
      return FoodItem(
        name: 'Test',
        category: category,
        calories: 165,
        protein: protein,
        carbohydrates: carbohydrates,
        fat: fat,
        fiber: 0,
        sugars: 0,
        sodium: 0,
        cholesterol: 0,
        mealType: 'Lunch',
        waterIntake: 0,
      );
    }

    test('totalMacros sums protein + carbohydrates + fat', () {
      final food = makeFood(protein: 10, carbohydrates: 20, fat: 5);
      expect(food.totalMacros, closeTo(35, 0.01));
    });

    test('totalMacros is 0 when all macros are 0', () {
      final food = makeFood(protein: 0, carbohydrates: 0, fat: 0);
      expect(food.totalMacros, closeTo(0, 0.01));
    });

    test('primaryCategory returns full category when no slash', () {
      final food = makeFood(category: 'Vegetables');
      expect(food.primaryCategory, 'Vegetables');
    });

    test('primaryCategory returns text before first slash for multi-category', () {
      final food = makeFood(category: 'Protein/Dairy');
      expect(food.primaryCategory, 'Protein');
    });

    test('primaryCategory with multiple slashes returns first segment only', () {
      final food = makeFood(category: 'A/B/C');
      expect(food.primaryCategory, 'A');
    });
  });

  group('FoodItem.toJson', () {
    test('serializes all fields', () {
      final food = FoodItem(
        name: 'Chicken Breast',
        category: 'Protein',
        calories: 165,
        protein: 31,
        carbohydrates: 0,
        fat: 3.6,
        fiber: 0,
        sugars: 0,
        sodium: 74,
        cholesterol: 85,
        mealType: 'Lunch',
        waterIntake: 0,
      );

      final json = food.toJson();

      expect(json['name'], 'Chicken Breast');
      expect(json['calories'], 165);
      expect(json['protein'], 31);
      expect(json['mealType'], 'Lunch');
    });
  });

  group('MealEntry.fromFood', () {
    test('creates MealEntry with nutrients from FoodItem (1 serving)', () {
      final food = FoodItem(
        name: 'Oatmeal',
        category: 'Grains',
        calories: 150,
        protein: 5,
        carbohydrates: 27,
        fat: 2.5,
        fiber: 4,
        sugars: 1,
        sodium: 0,
        cholesterol: 0,
        mealType: 'Breakfast',
        waterIntake: 240,
      );

      final entry = MealEntry.fromFood(food, 1.0, 'Breakfast');

      expect(entry.foodName, 'Oatmeal');
      expect(entry.servings, 1.0);
      expect(entry.calories, 150);
      expect(entry.protein, 5);
      expect(entry.mealType, 'Breakfast');
    });

    test('stores servings value (nutrients are per-serving base values)', () {
      final food = FoodItem(
        name: 'Rice',
        category: 'Grains',
        calories: 200,
        protein: 4,
        carbohydrates: 44,
        fat: 0.4,
        fiber: 0.6,
        sugars: 0,
        sodium: 1,
        cholesterol: 0,
        mealType: 'Lunch',
        waterIntake: 0,
      );

      final entry = MealEntry.fromFood(food, 2.0, 'Lunch');
      expect(entry.servings, 2.0);
    });

    test('timestamp is set to a non-empty ISO string', () {
      final food = FoodItem(
        name: 'Egg',
        category: 'Protein',
        calories: 70,
        protein: 6,
        carbohydrates: 0.6,
        fat: 5,
        fiber: 0,
        sugars: 0.6,
        sodium: 62,
        cholesterol: 186,
        mealType: 'Breakfast',
        waterIntake: 0,
      );
      final entry = MealEntry.fromFood(food, 1.0, 'Breakfast');
      expect(entry.timestamp, isNotEmpty);
      expect(DateTime.tryParse(entry.timestamp), isNotNull);
    });
  });

  group('MealEntry JSON round-trip', () {
    test('toJson → fromJson preserves all fields', () {
      final original = MealEntry(
        foodName: 'Salmon',
        category: 'Protein',
        servings: 1.5,
        calories: 300,
        protein: 40,
        carbohydrates: 0,
        fat: 15,
        fiber: 0,
        sugars: 0,
        sodium: 80,
        cholesterol: 100,
        waterIntake: 0,
        mealType: 'Dinner',
        timestamp: '2024-01-01T12:00:00.000',
      );

      final json = original.toJson();
      final restored = MealEntry.fromJson(json);

      expect(restored.foodName, original.foodName);
      expect(restored.servings, original.servings);
      expect(restored.calories, original.calories);
      expect(restored.protein, original.protein);
      expect(restored.mealType, original.mealType);
      expect(restored.timestamp, original.timestamp);
    });

    test('fromJson uses defaults for missing fields', () {
      final entry = MealEntry.fromJson({});
      expect(entry.foodName, '');
      expect(entry.servings, 1.0);
      expect(entry.calories, 0.0);
      expect(entry.mealType, 'Snack');
    });
  });
}
