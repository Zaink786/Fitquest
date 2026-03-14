import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../models/routine_model.dart';
import '../../models/workout_session_model.dart';
import '../../services/exercise_service.dart';
import '../../services/routine_service.dart';
import '../../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  static const List<String> _planTemplates = [
    'Push',
    'Pull',
    'Legs',
    'Upper',
    'Full Body',
  ];

  List<Routine> _routines = [];
  List<Exercise> _allExercises = [];
  bool _isLoading = true;
  bool _isRoutinesExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final routines = await RoutineService.getRoutines();
      final exercises = await _exerciseService.loadExercises();
      if (mounted) {
        setState(() {
          _routines = routines;
          _allExercises = exercises;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Ad-hoc workouts ────────────────────────────────────────────────────────

  void _startEmptyWorkout() =>
      _showExercisePicker(_allExercises, 'Browse Exercises');

  Future<void> _generateWorkout() async {
    final exercises = await _exerciseService.getRandomWorkout(count: 6);
    if (!mounted) return;
    _showExercisePicker(exercises, 'Generated Workout');
  }

  void _showExercisePicker(List<Exercise> exercises, String title) {
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No exercises found')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            _sheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${exercises.length} exercises available',
                  style: TextStyle(color: Colors.grey[600])),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: exercises.length,
                itemBuilder: (_, i) {
                  final ex = exercises[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(ex.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${ex.getPrimaryMusclesDisplay()} · ${ex.getEquipmentDisplay()}'),
                      trailing: const Text('+20 XP',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _logAdHocExercise(ex);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logAdHocExercise(Exercise exercise) {
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    final weightCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(exercise.name,
            style: const TextStyle(fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  '${exercise.getPrimaryMusclesDisplay()} · ${_cap(exercise.level)}',
                  style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 16),
              _numField(setsCtrl, 'Sets'),
              const SizedBox(height: 12),
              _numField(repsCtrl, 'Reps per Set'),
              const SizedBox(height: 12),
              _numField(weightCtrl, 'Weight (kg) – optional',
                  decimal: true),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final sets = int.tryParse(setsCtrl.text) ?? 3;
              final reps = int.tryParse(repsCtrl.text) ?? 10;
              final weight = double.tryParse(weightCtrl.text);

              final workoutEx = WorkoutExercise.fromExercise(
                  exercise: exercise,
                  sets: sets,
                  reps: reps,
                  weight: weight);
              final session = WorkoutSession(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: '${exercise.category} Workout',
                date: DateTime.now(),
                exercises: [workoutEx],
                totalPoints: workoutEx.pointsEarned,
              );
              await StorageService.saveWorkout(session);
              await StorageService.addPoints(session.totalPoints);
              await StorageService.addDailyPoints(session.totalPoints);
              await StorageService.checkFirstWorkoutAchievement();
              await StorageService.updateStreak();
              await StorageService.checkStreakAchievement(
                  StorageService.getCurrentStreak());

              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '${exercise.name} logged! +${session.totalPoints} XP'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ));
              }
            },
            child: const Text('Log Workout'),
          ),
        ],
      ),
    );
  }

  // ── Routines ───────────────────────────────────────────────────────────────

  Future<void> _openRoutineForm({
    Routine? existing,
    String? initialName,
    List<RoutineExercise>? initialExercises,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _RoutineFormSheet(
        existing: existing,
        initialName: initialName,
        initialExercises: initialExercises,
        allExercises: _allExercises,
        onSave: (routine) async {
          await RoutineService.saveRoutine(routine);
          if (ctx.mounted) Navigator.pop(ctx);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deleteRoutine(Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine'),
        content:
            Text('Delete "${routine.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await RoutineService.deleteRoutine(routine.id);
      await _loadData();
    }
  }

  Future<void> _createTemplatePlan(String templateName) async {
    final existingRoutine = _routines.cast<Routine?>().firstWhere(
          (routine) =>
              routine != null &&
              routine.name.toLowerCase() == templateName.toLowerCase(),
          orElse: () => null,
        );

    if (existingRoutine != null) {
      await _openRoutineForm(existing: existingRoutine);
      return;
    }

    await _openRoutineForm(
      initialName: templateName,
      initialExercises: _buildTemplateExercises(templateName),
    );
  }

  List<RoutineExercise> _buildTemplateExercises(String templateName) {
    List<Exercise> selected;

    switch (templateName.toLowerCase()) {
      case 'push':
        selected = _pickExercisesForMuscles(
          const ['chest', 'shoulders', 'triceps'],
          targetCount: 6,
        );
        break;
      case 'pull':
        selected = _pickExercisesForMuscles(
          const ['lats', 'middle back', 'lower back', 'traps', 'biceps'],
          targetCount: 6,
        );
        break;
      case 'legs':
        selected = _pickExercisesForMuscles(
          const ['quadriceps', 'hamstrings', 'glutes', 'calves'],
          targetCount: 6,
        );
        break;
      case 'upper':
        selected = _pickExercisesForMuscles(
          const ['chest', 'lats', 'middle back', 'shoulders', 'biceps', 'triceps'],
          targetCount: 8,
        );
        break;
      case 'full body':
        selected = _pickExercisesForMuscles(
          const ['quadriceps', 'hamstrings', 'chest', 'lats', 'shoulders', 'abdominals'],
          targetCount: 8,
        );
        break;
      default:
        selected = _allExercises.take(6).toList();
    }

    return selected
        .map(
          (exercise) => RoutineExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
          ),
        )
        .toList();
  }

  List<Exercise> _pickExercisesForMuscles(
    List<String> muscleHints, {
    required int targetCount,
  }) {
    final picked = <Exercise>[];
    final seenIds = <String>{};

    for (final hint in muscleHints) {
      for (final exercise in _allExercises) {
        if (seenIds.contains(exercise.id)) {
          continue;
        }

        final primary = exercise.primaryMuscles.map((m) => m.toLowerCase());
        final secondary = exercise.secondaryMuscles.map((m) => m.toLowerCase());
        final matches = primary.any((m) => m.contains(hint)) ||
            secondary.any((m) => m.contains(hint));

        if (!matches) {
          continue;
        }

        seenIds.add(exercise.id);
        picked.add(exercise);
        break;
      }

      if (picked.length >= targetCount) {
        break;
      }
    }

    if (picked.length < targetCount) {
      for (final exercise in _allExercises) {
        if (seenIds.add(exercise.id)) {
          picked.add(exercise);
        }
        if (picked.length >= targetCount) {
          break;
        }
      }
    }

    return picked;
  }

  Future<void> _startRoutine(Routine routine) async {
    if (routine.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Add exercises to this routine first')),
      );
      return;
    }
    final workoutExercises = routine.exercises
        .map((re) => WorkoutExercise(
              exerciseId: re.exerciseId,
              exerciseName: re.exerciseName,
              exerciseLevel: 'intermediate',
              sets: re.sets,
              reps: re.reps,
              weight: re.weight,
              pointsEarned: 20,
            ))
        .toList();
    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: routine.name,
      date: DateTime.now(),
      exercises: workoutExercises,
      totalPoints: workoutExercises.length * 20,
    );
    await StorageService.saveWorkout(session);
    await StorageService.addPoints(session.totalPoints);
    await StorageService.addDailyPoints(session.totalPoints);
    await StorageService.checkFirstWorkoutAchievement();
    await StorageService.updateStreak();
    await StorageService.checkStreakAchievement(
        StorageService.getCurrentStreak());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${routine.name} complete! +${session.totalPoints} XP 💪'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _cap(String t) =>
      t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

  static Widget _sheetHandle() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2)),
      );

  static TextField _numField(TextEditingController ctrl, String label,
          {bool decimal = false}) =>
      TextField(
        controller: ctrl,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workouts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── New Workout ──────────────────────────────
                    const Text('New Workout',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _NewWorkoutCard(
                      label: 'Start Empty Workout',
                      icon: Icons.fitness_center,
                      color: Colors.blue,
                      onTap: _startEmptyWorkout,
                    ),
                    const SizedBox(height: 10),
                    _NewWorkoutCard(
                      label: 'Generate Workout',
                      icon: Icons.auto_awesome,
                      color: Colors.purple,
                      onTap: _generateWorkout,
                    ),
                    const SizedBox(height: 28),

                    // ── Routines header ──────────────────────────
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Routines',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Icon(Icons.folder_outlined,
                                color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _openRoutineForm(),
                              child: const Icon(Icons.add,
                                  color: Colors.blue, size: 28),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _planTemplates.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, index) {
                          final plan = _planTemplates[index];
                          return _PlanTemplateChip(
                            label: plan,
                            onTap: () => _createTemplatePlan(plan),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Empty state ──────────────────────────────
                    if (_routines.isEmpty)
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.folder_open,
                                  size: 52,
                                  color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('No routines yet',
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _openRoutineForm(),
                                icon: const Icon(Icons.add),
                                label: const Text('Create Routine'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // ── Collapsible group header ─────────────
                      InkWell(
                        onTap: () => setState(() =>
                            _isRoutinesExpanded =
                                !_isRoutinesExpanded),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isRoutinesExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_right,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'My Routines (${_routines.length})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Routine cards ────────────────────────
                      if (_isRoutinesExpanded) ...[
                        const SizedBox(height: 10),
                        ..._routines.map((r) => _RoutineCard(
                              routine: r,
                              onEdit: () =>
                                  _openRoutineForm(existing: r),
                              onDelete: () => _deleteRoutine(r),
                              onStart: () => _startRoutine(r),
                            )),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New Workout button card
// ─────────────────────────────────────────────────────────────────────────────

class _NewWorkoutCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NewWorkoutCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border:
              Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
            Icon(icon, size: 42, color: color.withValues(alpha: 0.75)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saved routine card
// ─────────────────────────────────────────────────────────────────────────────

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStart;

  const _RoutineCard({
    required this.routine,
    required this.onEdit,
    required this.onDelete,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    const previewLimit = 3;
    final preview = routine.exercises.take(previewLimit).toList();
    final extra = routine.exercises.length - previewLimit;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(routine.name,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${routine.totalSets} sets',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit routine')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),

            // Exercise list preview
            if (routine.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('No exercises yet – tap ⋮ to edit',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 13)),
              )
            else ...[
              const Divider(height: 16),
              ...preview.map((re) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              Colors.blue.withValues(alpha: 0.12),
                          child: const Icon(Icons.fitness_center,
                              size: 16, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(re.exerciseName,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                            '${re.sets} sets'
                            '${re.weight != null ? ' · ${re.weight!.toStringAsFixed(1)} kg' : ''}',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12)),
                      ],
                    ),
                  )),
              if (extra > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('and $extra more',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 13)),
                ),
            ],

            const SizedBox(height: 10),
            // START button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('START',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PlanTemplateChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.blue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create / Edit routine bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RoutineFormSheet extends StatefulWidget {
  final Routine? existing;
  final String? initialName;
  final List<RoutineExercise>? initialExercises;
  final List<Exercise> allExercises;
  final Future<void> Function(Routine) onSave;

  const _RoutineFormSheet({
    this.existing,
    this.initialName,
    this.initialExercises,
    required this.allExercises,
    required this.onSave,
  });

  @override
  State<_RoutineFormSheet> createState() => _RoutineFormSheetState();
}

class _RoutineFormSheetState extends State<_RoutineFormSheet> {
  final _nameCtrl = TextEditingController();
  List<RoutineExercise> _exercises = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      // Deep-copy so edits don't touch the originals until saved
      _exercises = widget.existing!.exercises
          .map((e) => RoutineExercise(
                exerciseId: e.exerciseId,
                exerciseName: e.exerciseName,
                sets: e.sets,
                reps: e.reps,
                weight: e.weight,
              ))
          .toList();
    } else {
      _nameCtrl.text = widget.initialName ?? '';
      _exercises = (widget.initialExercises ?? [])
          .map((e) => RoutineExercise(
                exerciseId: e.exerciseId,
                exerciseName: e.exerciseName,
                sets: e.sets,
                reps: e.reps,
                weight: e.weight,
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _pickExercise() {
    final addedIds = _exercises.map((e) => e.exerciseId).toSet();
    final available =
        widget.allExercises.where((e) => !addedIds.contains(e.id)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  const Text('Add Exercise',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: available.length,
                itemBuilder: (_, i) {
                  final ex = available[i];
                  return ListTile(
                    title: Text(ex.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(ex.getPrimaryMusclesDisplay()),
                    trailing: const Icon(Icons.add_circle_outline,
                        color: Colors.blue),
                    onTap: () {
                      setState(() {
                        _exercises.add(RoutineExercise(
                          exerciseId: ex.id,
                          exerciseName: ex.name,
                        ));
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a routine name')),
      );
      return;
    }
    setState(() => _saving = true);
    final routine = Routine(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      exercises: _exercises,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    await widget.onSave(routine);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text(
                    widget.existing == null
                        ? 'New Routine'
                        : 'Edit Routine',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : const Text('Save',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // Name field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Routine name',
                  hintText: 'e.g. Push, Pull, Legs, Upper…',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Exercise list
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  ..._exercises.asMap().entries.map((entry) {
                    final i = entry.key;
                    final re = entry.value;
                    return _ExerciseEditTile(
                      key: ValueKey(re.exerciseId + i.toString()),
                      routineExercise: re,
                      onDelete: () =>
                          setState(() => _exercises.removeAt(i)),
                    );
                  }),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: _pickExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise tile inside the form (editable sets / reps / weight)
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseEditTile extends StatefulWidget {
  final RoutineExercise routineExercise;
  final VoidCallback onDelete;

  const _ExerciseEditTile({
    super.key,
    required this.routineExercise,
    required this.onDelete,
  });

  @override
  State<_ExerciseEditTile> createState() => _ExerciseEditTileState();
}

class _ExerciseEditTileState extends State<_ExerciseEditTile> {
  late final TextEditingController _weightCtrl;

  @override
  void initState() {
    super.initState();
    final w = widget.routineExercise.weight;
    _weightCtrl = TextEditingController(
        text: w != null ? w.toStringAsFixed(1) : '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final re = widget.routineExercise;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(re.exerciseName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Sets:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                _Stepper(
                  value: re.sets,
                  min: 1,
                  max: 20,
                  onChanged: (v) => setState(() => re.sets = v),
                ),
                const SizedBox(width: 14),
                const Text('Reps:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                _Stepper(
                  value: re.reps,
                  min: 1,
                  max: 100,
                  onChanged: (v) => setState(() => re.reps = v),
                ),
                const SizedBox(width: 14),
                const Text('kg:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                SizedBox(
                  width: 58,
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: '—',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        re.weight = double.tryParse(v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tiny +/- stepper
// ─────────────────────────────────────────────────────────────────────────────

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  Widget _btn(IconData icon, bool enabled, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: enabled ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.remove, value > min,
            value > min ? () => onChanged(value - 1) : null),
        const SizedBox(width: 6),
        Text('$value',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 6),
        _btn(Icons.add, value < max,
            value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}
