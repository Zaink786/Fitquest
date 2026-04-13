import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/active_workout_model.dart';
import '../../models/quest_model.dart';
import '../../models/routine_model.dart';
import '../../models/workout_session_model.dart';
import '../../services/storage_service.dart';
import '../../services/quest_service.dart';
import 'active_exercise_sheet.dart';

/// Full-screen active workout session launched when the user presses START
/// on a routine. Exercises are listed and tapped individually to log sets.
class ActiveWorkoutScreen extends StatefulWidget {
  final Routine routine;

  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late List<ActiveExerciseEntry> _entries;
  late DateTime _startTime;
  late Timer _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Pre-populate each exercise with sets from the routine defaults.
    _entries = widget.routine.exercises
        .map(
          (re) => ActiveExerciseEntry(
            exerciseId: re.exerciseId,
            exerciseName: re.exerciseName,
            sets: List.generate(
              re.sets,
              (_) => ActiveSet(kg: re.weight, reps: re.reps),
            ),
          ),
        )
        .toList();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // ── Helpers

  String get _timerDisplay {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _totalXp => _entries.fold(0, (sum, e) => sum + e.completedSets * 20);

  // ── Actions

  void _openExercise(ActiveExerciseEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          ActiveExerciseSheet(entry: entry, onChanged: () => setState(() {})),
    );
  }

  Future<void> _finishWorkout() async {
    final completedEntries = _entries
        .where((e) => e.completedSets > 0)
        .toList();

    if (completedEntries.isEmpty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No sets completed'),
          content: const Text(
            'Tick at least one set before finishing, or discard this workout.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep going'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard == true && mounted) Navigator.pop(context);
      return;
    }

    final confirmed = await _showSummaryDialog(completedEntries);
    if (confirmed != true || !mounted) return;

    final workoutExercises = completedEntries.map((e) {
      final doneSets = e.sets.where((s) => s.isDone).toList();
      // Compute average reps/weight across the ticked sets.
      final avgReps = doneSets.isEmpty
          ? 1
          : (doneSets.map((s) => s.reps).reduce((a, b) => a + b) /
                    doneSets.length)
                .round();
      final weights = doneSets.map((s) => s.kg).whereType<double>().toList();
      final avgWeight = weights.isEmpty
          ? null
          : weights.reduce((a, b) => a + b) / weights.length;

      return WorkoutExercise(
        exerciseId: e.exerciseId,
        exerciseName: e.exerciseName,
        exerciseLevel: 'intermediate',
        sets: doneSets.length,
        reps: avgReps,
        weight: avgWeight,
        pointsEarned: doneSets.length * 20,
      );
    }).toList();

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.routine.name,
      date: _startTime,
      exercises: workoutExercises,
      totalPoints: WorkoutSession.calculateTotalPoints(workoutExercises),
      durationSeconds: _elapsedSeconds,
    );

    final questResult = await QuestService.processWorkoutCompletion(
      workoutExercises,
    );

    await StorageService.saveWorkout(session);
    await StorageService.addPoints(session.totalPoints);
    await StorageService.addDailyPoints(session.totalPoints);
    await StorageService.checkFirstWorkoutAchievement();
    await StorageService.updateStreak();
    await StorageService.checkStreakAchievement(
      StorageService.getCurrentStreak(),
    );

    if (mounted && questResult.newWorldUnlocked != null) {
      await _showWorldUnlockDialog(questResult.newWorldUnlocked!);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.routine.name} complete! +${session.totalPoints} XP 💪',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _showWorldUnlockDialog(QuestWorld world) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: world.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(world.icon, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              const Text(
                'New World Unlocked!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                world.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                world.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Keep Going!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showSummaryDialog(List<ActiveExerciseEntry> completed) {
    final totalSets = completed.fold<int>(0, (s, e) => s + e.completedSets);
    final xp = totalSets * 20;
    final mins = _elapsedSeconds ~/ 60;
    final secs = _elapsedSeconds % 60;
    final duration = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
              icon: Icons.fitness_center,
              label: 'Exercises',
              value: '${completed.length}',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.repeat,
              label: 'Sets completed',
              value: '$totalSets',
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: duration,
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.star_outline,
              label: 'XP earned',
              value: '+$xp XP',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Workout'),
          ),
        ],
      ),
    );
  }

  // ── Build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.routine.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              _timerDisplay,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Text(
              '+$_totalXp XP',
              style: const TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _finishWorkout,
            child: const Text(
              'Finish',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _entries.length,
        itemBuilder: (_, i) => _ExerciseTile(
          entry: _entries[i],
          onTap: () => _openExercise(_entries[i]),
        ),
      ),
    );
  }
}

// Exercise list tile

class _ExerciseTile extends StatelessWidget {
  final ActiveExerciseEntry entry;
  final VoidCallback onTap;

  const _ExerciseTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = entry.completedSets;
    final total = entry.sets.length;
    final isComplete = done == total && total > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isComplete
              ? Colors.green
              : const Color(0xFF1A237E).withValues(alpha: 0.12),
          child: isComplete
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : const Icon(Icons.fitness_center, color: Color(0xFF1A237E), size: 20),
        ),
        title: Text(
          entry.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          done == 0 ? '$total sets · tap to log' : '$done / $total sets done',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

// Summary dialog row

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[700])),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
