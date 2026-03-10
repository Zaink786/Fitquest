import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_session_model.dart';
import '../../services/exercise_service.dart';
import '../../services/storage_service.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  
  List<WorkoutSession> _workoutSessions = [];
  List<Exercise> _availableExercises = [];
  bool _isLoading = true;
  int _totalExercises = 0;

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _loadSavedWorkouts();
  }

  Future<void> _loadSavedWorkouts() async {
    final savedWorkouts = StorageService.getAllWorkouts();
    setState(() {
      _workoutSessions = savedWorkouts;
    });
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    
    try {
      final exercises = await _exerciseService.loadExercises();
      setState(() {
        _availableExercises = exercises;
        _totalExercises = exercises.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercises: $e')),
        );
      }
    }
  }

  void _startWorkout() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Workout Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.blue),
              title: const Text('Strength Training'),
              onTap: () => Navigator.pop(context, 'strength'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_run, color: Colors.orange),
              title: const Text('Cardio'),
              onTap: () => Navigator.pop(context, 'cardio'),
            ),
            ListTile(
              leading: const Icon(Icons.self_improvement, color: Colors.green),
              title: const Text('Stretching'),
              onTap: () => Navigator.pop(context, 'stretching'),
            ),
            ListTile(
              leading: const Icon(Icons.shuffle, color: Colors.purple),
              title: const Text('Quick Random Workout'),
              onTap: () => Navigator.pop(context, 'random'),
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.teal),
              title: const Text('Browse All Exercises'),
              onTap: () => Navigator.pop(context, 'browse'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      _handleWorkoutSelection(result);
    }
  }

  void _handleWorkoutSelection(String type) async {
    if (type == 'random') {
      final exercises = await _exerciseService.getRandomWorkout(count: 8);
      _showExerciseSelector(exercises, 'Random Workout');
    } else if (type == 'browse') {
      _showExerciseSelector(_availableExercises, 'All Exercises');
    } else {
      final exercises = await _exerciseService.getExercisesByCategory(type);
      _showExerciseSelector(exercises, '${_capitalize(type)} Exercises');
    }
  }

  void _showExerciseSelector(List<Exercise> exercises, String title) {
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No exercises found for this category')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${exercises.length} exercises available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            exercise.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Level: ${_capitalize(exercise.level)}'),
                              Text('Muscles: ${exercise.getPrimaryMusclesDisplay()}'),
                              Text('Equipment: ${exercise.getEquipmentDisplay()}'),
                            ],
                          ),
                          trailing: Chip(
                            label: const Text('20 pts'),
                            backgroundColor: Colors.blue.withOpacity(0.2),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _addExerciseToWorkout(exercise);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addExerciseToWorkout(Exercise exercise) {
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          exercise.name,
          style: const TextStyle(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level: ${_capitalize(exercise.level)}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              Text(
                'Target: ${exercise.getPrimaryMusclesDisplay()}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sets',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reps per Set',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg/lbs) - Optional',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final sets = int.tryParse(setsController.text) ?? 3;
              final reps = int.tryParse(repsController.text) ?? 10;
              final weight = double.tryParse(weightController.text);
              
              final workoutExercise = WorkoutExercise.fromExercise(
                exercise: exercise,
                sets: sets,
                reps: reps,
                weight: weight,
              );

              final session = WorkoutSession(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: '${exercise.category} Workout',
                date: DateTime.now(),
                exercises: [workoutExercise],
                totalPoints: workoutExercise.pointsEarned,
              );

              // Save to storage
              await StorageService.saveWorkout(session);
              
              // Add points (both total and daily)
              await StorageService.addPoints(session.totalPoints);
              await StorageService.addDailyPoints(session.totalPoints);
              
              // Check achievements
              await StorageService.checkFirstWorkoutAchievement();
              
              // Update streak and check streak achievement
              await StorageService.updateStreak();
              final streak = StorageService.getCurrentStreak();
              await StorageService.checkStreakAchievement(streak);

              setState(() {
                _workoutSessions.add(session);
              });

              Navigator.pop(context);

              // Check if achievement was just unlocked
              final dailyPoints = StorageService.getDailyPoints();
              String message = 'Workout logged! Earned ${session.totalPoints} points!';
              if (dailyPoints >= 100 && StorageService.isAchievementUnlocked('first_100_points')) {
                message += '\n🎉 Achievement Unlocked: Century Club!';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: const Text('Log Workout'),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading exercise database...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Exercise Database'),
                  content: Text(
                    '$_totalExercises exercises loaded\n'
                    'from free-exercise-db\n\n'
                    'Tap the + button to start logging workouts!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _workoutSessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No workouts logged yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to start',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '$_totalExercises exercises ready',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _workoutSessions.length,
              itemBuilder: (context, index) {
                final session = _workoutSessions[_workoutSessions.length - 1 - index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${session.totalPoints}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      session.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${session.date.toString().split('.')[0]}\n'
                      '${session.exercises.length} exercise(s) • ${session.totalPoints} points',
                    ),
                    children: session.exercises.map((workoutEx) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(workoutEx.exerciseName),
                        subtitle: Text(
                          '${workoutEx.sets} sets × ${workoutEx.reps} reps'
                          '${workoutEx.weight != null ? ' @ ${workoutEx.weight}kg' : ''}',
                        ),
                        trailing: Text(
                          '+${workoutEx.pointsEarned} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startWorkout,
        icon: const Icon(Icons.add),
        label: const Text('Log Workout'),
      ),
    );
  }
}
