import 'package:flutter/material.dart';
import '../../models/food_model.dart';
import '../../services/nutrition_service.dart';
import '../../services/storage_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final NutritionService _nutritionService = NutritionService();

  List<MealEntry> _todaysMeals = [];
  Map<String, double> _todaysMacros = {};
  bool _isLoading = true;
  int _totalFoods = 0;

  // Daily goals
  double _calorieGoal = 2000;
  final double _proteinGoal = 150;
  final double _carbsGoal = 250;
  final double _fatGoal = 65;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final meals = await NutritionService.getTodaysMeals();
      final macros = await NutritionService.getTodaysMacros();
      final stats = await _nutritionService.getDatabaseStats();
      final calorieGoal = await NutritionService.getCalorieGoal();
      setState(() {
        _todaysMeals = meals;
        _todaysMacros = macros;
        _totalFoods = stats['totalFoods'] ?? 0;
        _calorieGoal = calorieGoal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading nutrition data: $e')),
        );
      }
    }
  }

  Future<void> _showEditCalorieGoalDialog() async {
    final controller = TextEditingController(
      text: _calorieGoal.toInt().toString(),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _CalorieGoalDialog(controller: controller),
    );
    if (result != null) {
      await NutritionService.saveCalorieGoal(result);
      setState(() => _calorieGoal = result);
    }
  }

  void _showAddFoodDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Food'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wb_sunny, color: Colors.orange),
              title: const Text('Breakfast'),
              onTap: () => Navigator.pop(context, 'Breakfast'),
            ),
            ListTile(
              leading: const Icon(Icons.lunch_dining, color: Colors.green),
              title: const Text('Lunch'),
              onTap: () => Navigator.pop(context, 'Lunch'),
            ),
            ListTile(
              leading: const Icon(Icons.dinner_dining, color: Colors.indigo),
              title: const Text('Dinner'),
              onTap: () => Navigator.pop(context, 'Dinner'),
            ),
            ListTile(
              leading: const Icon(Icons.cookie, color: Colors.brown),
              title: const Text('Snack'),
              onTap: () => Navigator.pop(context, 'Snack'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      _showFoodSearch(result);
    }
  }

  void _showFoodSearch(String mealType) async {
    final foods = await _nutritionService.loadFoods();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FoodSearchSheet(
        foods: foods,
        mealType: mealType,
        nutritionService: _nutritionService,
        onFoodLogged: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nutrition',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_totalFoods foods in database',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddFoodDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Log Food'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Calorie summary card
                    _buildCalorieSummaryCard(),

                    const SizedBox(height: 16),

                    // Macro breakdown
                    _buildMacroBreakdownCard(),

                    const SizedBox(height: 16),

                    // Micronutrients card
                    _buildMicronutrientsCard(),

                    const SizedBox(height: 16),

                    // Today's meals
                    _buildTodaysMealsSection(),
                  ],
                ),
              ),
          ),
        ),
    );
  }

  Widget _buildCalorieSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final consumed = _todaysMacros['calories'] ?? 0;
    final remaining = _calorieGoal - consumed;
    final progress = (consumed / _calorieGoal).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Calories Today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text(
                      '${consumed.toInt()} / ${_calorieGoal.toInt()} kcal',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _showEditCalorieGoalDialog,
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3E2800) : const Color(0xFFFFF8E1),
                border: const Border(
                  left: BorderSide(color: Color(0xFFFB8C00), width: 2),
                ),
              ),
              child: const Text(
                'Calorie and macro values are estimates. Consult a dietitian for personalised advice.',
                style: TextStyle(fontSize: 10, color: Color(0xFFE65100)),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  consumed > _calorieGoal ? Colors.red : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCalorieDetail('Consumed', consumed.toInt(), Colors.green),
                _buildCalorieDetail(
                  'Remaining',
                  remaining > 0 ? remaining.toInt() : 0,
                  remaining > 0 ? Colors.grey : Colors.red,
                ),
                _buildCalorieDetail('Goal', _calorieGoal.toInt(), const Color(0xFF9FA8DA)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieDetail(String label, int value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
      ],
    );
  }

  Widget _buildMacroBreakdownCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Macronutrients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildMacroRow(
              'Protein',
              _todaysMacros['protein'] ?? 0,
              _proteinGoal,
              Colors.red[400]!,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              'Carbs',
              _todaysMacros['carbohydrates'] ?? 0,
              _carbsGoal,
              Colors.amber[600]!,
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              'Fat',
              _todaysMacros['fat'] ?? 0,
              _fatGoal,
              const Color(0xFF9FA8DA),
            ),
            const SizedBox(height: 12),
            _buildMacroRow(
              'Fiber',
              _todaysMacros['fiber'] ?? 0,
              30, // recommended daily fiber
              Colors.green[400]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String name, double current, double goal, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (current / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${current.toStringAsFixed(1)}g / ${goal.toInt()}g',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMicronutrientsCard() {
    final sodium = _todaysMacros['sodium'] ?? 0;
    final cholesterol = _todaysMacros['cholesterol'] ?? 0;
    final sugars = _todaysMacros['sugars'] ?? 0;
    final water = _todaysMacros['water'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Other Nutrients & Hydration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'Sodium',
                    '${sodium.toInt()} mg',
                    Icons.water_drop,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
                    'Cholesterol',
                    '${cholesterol.toInt()} mg',
                    Icons.monitor_heart,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'Sugars',
                    '${sugars.toStringAsFixed(1)}g',
                    Icons.cake,
                    Colors.pink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniStat(
                    'Water',
                    '${water.toInt()} ml',
                    Icons.local_drink,
                    const Color(0xFF9FA8DA),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMealsSection() {
    final mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
    final mealIcons = {
      'Breakfast': Icons.wb_sunny,
      'Lunch': Icons.lunch_dining,
      'Dinner': Icons.dinner_dining,
      'Snack': Icons.cookie,
    };
    final mealColors = {
      'Breakfast': Colors.orange,
      'Lunch': Colors.green,
      'Dinner': Colors.indigo,
      'Snack': Colors.brown,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Meals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (_todaysMeals.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 28,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No meals logged today',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Log Food" to get started',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...mealTypes.map((type) {
            final meals = _todaysMeals
                .where((m) => m.mealType == type)
                .toList();
            if (meals.isEmpty) return const SizedBox.shrink();

            final totalCals = meals.fold<double>(
              0,
              (sum, m) => sum + (m.calories * m.servings),
            );

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          mealIcons[type],
                          color: mealColors[type],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${totalCals.toInt()} kcal',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    ...meals.map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${m.foodName}${m.servings != 1 ? ' x${m.servings}' : ''}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '${(m.calories * m.servings).toInt()} kcal',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ─── Food Search Bottom Sheet ───

class _FoodSearchSheet extends StatefulWidget {
  final List<FoodItem> foods;
  final String mealType;
  final NutritionService nutritionService;
  final VoidCallback onFoodLogged;

  const _FoodSearchSheet({
    required this.foods,
    required this.mealType,
    required this.nutritionService,
    required this.onFoodLogged,
  });

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _filteredFoods = [];
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _filteredFoods = widget.foods;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await widget.nutritionService.getCategories();
    setState(() {
      _categories = ['All', ...cats];
    });
  }

  void _filterFoods() {
    setState(() {
      _filteredFoods = widget.foods.where((f) {
        final matchesSearch =
            _searchController.text.isEmpty ||
            f.name.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'All' ||
            f.category.toLowerCase().contains(_selectedCategory.toLowerCase());
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  /// Check if the user hit their calorie goal and award bonus XP once/day.
  Future<void> _checkCalorieGoal() async {
    final macros = await NutritionService.getTodaysMacros();
    final consumed = macros['calories'] ?? 0;
    final goal = await NutritionService.getCalorieGoal();
    if (consumed >= goal && !StorageService.isCalorieGoalMetToday()) {
      await StorageService.awardCalorieGoalBonus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add to ${widget.mealType}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterFoods(),
                    decoration: InputDecoration(
                      hintText: 'Search foods...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Category chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final selected = cat == _selectedCategory;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                            _filterFoods();
                          },
                          selectedColor: Colors.green[100],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Food count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredFoods.length} foods',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Results list
            Expanded(
              child: _filteredFoods.isEmpty
                  ? Center(
                      child: Text(
                        'No foods found',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFoods.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final food = _filteredFoods[index];
                        return ListTile(
                          title: Text(
                            food.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${food.calories.toInt()} kcal · P: ${food.protein}g · C: ${food.carbohydrates}g · F: ${food.fat}g',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Text(
                            food.category,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          onTap: () => _showServingsDialog(food),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showServingsDialog(FoodItem food) {
    double servings = 1.0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(food.name, style: const TextStyle(fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Macro summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).brightness == Brightness.dark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _macroInfoRow(
                        'Calories',
                        '${(food.calories * servings).toInt()} kcal',
                      ),
                      _macroInfoRow(
                        'Protein',
                        '${(food.protein * servings).toStringAsFixed(1)}g',
                      ),
                      _macroInfoRow(
                        'Carbs',
                        '${(food.carbohydrates * servings).toStringAsFixed(1)}g',
                      ),
                      _macroInfoRow(
                        'Fat',
                        '${(food.fat * servings).toStringAsFixed(1)}g',
                      ),
                      _macroInfoRow(
                        'Fiber',
                        '${(food.fiber * servings).toStringAsFixed(1)}g',
                      ),
                      _macroInfoRow(
                        'Sugars',
                        '${(food.sugars * servings).toStringAsFixed(1)}g',
                      ),
                      _macroInfoRow(
                        'Sodium',
                        '${(food.sodium * servings).toInt()} mg',
                      ),
                      _macroInfoRow(
                        'Cholesterol',
                        '${(food.cholesterol * servings).toInt()} mg',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Category: ${food.category}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: servings > 0.5
                          ? () => setDialogState(() => servings -= 0.5)
                          : null,
                    ),
                    Text(
                      servings == servings.toInt()
                          ? '${servings.toInt()}'
                          : servings.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setDialogState(() => servings += 0.5),
                    ),
                  ],
                ),
                const Text('servings'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final entry = MealEntry.fromFood(
                    food,
                    servings,
                    widget.mealType,
                  );
                  await NutritionService.logMeal(entry);

                  // +5 XP for logging a meal
                  await StorageService.addPoints(5);
                  await StorageService.addDailyPoints(5);

                  // Check calorie goal after this meal
                  await _checkCalorieGoal();

                  widget.onFoodLogged();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${food.name} added to ${widget.mealType}',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _macroInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CalorieGoalDialog extends StatefulWidget {
  final TextEditingController controller;

  const _CalorieGoalDialog({required this.controller});

  @override
  State<_CalorieGoalDialog> createState() => _CalorieGoalDialogState();
}

class _CalorieGoalDialogState extends State<_CalorieGoalDialog> {
  String? _error;

  static const int _min = 500;
  static const int _max = 10000;

  void _submit() {
    final raw = widget.controller.text.trim();
    final value = double.tryParse(raw);

    if (value == null) {
      setState(() => _error = 'Please enter a valid number.');
      return;
    }
    if (value < _min) {
      setState(() => _error = 'Minimum goal is $_min kcal.');
      return;
    }
    if (value > _max) {
      setState(() => _error = 'Maximum goal is $_max kcal.');
      return;
    }

    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily Calorie Goal'),
      content: TextField(
        controller: widget.controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          labelText: 'Calories (kcal)',
          hintText: '$_min – $_max',
          border: const OutlineInputBorder(),
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
