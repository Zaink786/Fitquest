import 'package:flutter/material.dart';
import '../../models/active_workout_model.dart';
import '../../models/workout_session_model.dart';
import '../../services/storage_service.dart';

/// Bottom sheet for logging/editing sets on a single exercise during an
/// active workout session.
class ActiveExerciseSheet extends StatefulWidget {
  final ActiveExerciseEntry entry;

  /// Called when the sheet closes so the parent can rebuild.
  final VoidCallback onChanged;

  const ActiveExerciseSheet({
    super.key,
    required this.entry,
    required this.onChanged,
  });

  @override
  State<ActiveExerciseSheet> createState() => _ActiveExerciseSheetState();
}

class _ActiveExerciseSheetState extends State<ActiveExerciseSheet> {
  late List<TextEditingController> _kgCtrls;
  late List<TextEditingController> _repsCtrls;
  WorkoutSession? _lastSession;

  @override
  void initState() {
    super.initState();
    _buildControllers();
    _lastSession = StorageService.getLastSessionForExercise(
      widget.entry.exerciseId,
    );
  }

  void _buildControllers() {
    _kgCtrls = widget.entry.sets
        .map(
          (s) => TextEditingController(
            text: s.kg != null ? s.kg!.toStringAsFixed(1) : '',
          ),
        )
        .toList();
    _repsCtrls = widget.entry.sets
        .map((s) => TextEditingController(text: s.reps.toString()))
        .toList();
  }

  /// Write text-field values back into the model.
  void _syncToModel() {
    for (int i = 0; i < widget.entry.sets.length; i++) {
      widget.entry.sets[i].kg = double.tryParse(_kgCtrls[i].text);
      widget.entry.sets[i].reps =
          int.tryParse(_repsCtrls[i].text) ?? widget.entry.sets[i].reps;
    }
  }

  @override
  void dispose() {
    _syncToModel();
    widget.onChanged();
    for (final c in _kgCtrls) {
      c.dispose();
    }
    for (final c in _repsCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSet() {
    _syncToModel();
    final last = widget.entry.sets.isNotEmpty
        ? widget.entry.sets.last
        : ActiveSet();
    setState(() {
      widget.entry.sets.add(ActiveSet(kg: last.kg, reps: last.reps));
      _kgCtrls.add(
        TextEditingController(
          text: last.kg != null ? last.kg!.toStringAsFixed(1) : '',
        ),
      );
      _repsCtrls.add(TextEditingController(text: last.reps.toString()));
    });
  }

  void _removeLastSet() {
    if (widget.entry.sets.isEmpty) return;
    setState(() {
      widget.entry.sets.removeLast();
      _kgCtrls.removeLast().dispose();
      _repsCtrls.removeLast().dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prevExercise = _lastSession?.exercises
        .where((e) => e.exerciseId == widget.entry.exerciseId)
        .firstOrNull;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.entry.exerciseName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // ── Table header ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 32,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'KG',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'REPS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 4),

                // ── Set rows ─────────────────────────────────────
                ...widget.entry.sets.asMap().entries.map((entry) {
                  final i = entry.key;
                  final set = entry.value;
                  return _SetRow(
                    index: i,
                    isDone: set.isDone,
                    kgCtrl: _kgCtrls[i],
                    repsCtrl: _repsCtrls[i],
                    onTick: () {
                      _syncToModel();
                      setState(() => set.isDone = !set.isDone);
                    },
                  );
                }),
                const SizedBox(height: 12),

                // ── Add / Remove set buttons ─────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addSet,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Set'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: widget.entry.sets.isNotEmpty
                          ? _removeLastSet
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Icon(Icons.remove, size: 16),
                    ),
                  ],
                ),

                // ── Previous session block ───────────────────────
                if (_lastSession != null && prevExercise != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(_lastSession!.date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'KG',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'REPS',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...List.generate(prevExercise.sets, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    prevExercise.weight != null
                                        ? prevExercise.weight!.toStringAsFixed(
                                            1,
                                          )
                                        : '—',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${prevExercise.reps}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final wd = weekdays[date.weekday - 1];
    final mo = months[date.month - 1];
    final ord = _ordinal(date.day);
    return '$wd, $mo ${date.day}$ord ${date.year}';
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

// Single set row widget

class _SetRow extends StatelessWidget {
  final int index;
  final bool isDone;
  final TextEditingController kgCtrl;
  final TextEditingController repsCtrl;
  final VoidCallback onTick;

  const _SetRow({
    required this.index,
    required this.isDone,
    required this.kgCtrl,
    required this.repsCtrl,
    required this.onTick,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: isDone
          ? BoxDecoration(
              color: const Color(0xFF1A237E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: TextField(
              controller: kgCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: '—',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTick,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF1A237E) : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check,
                size: 20,
                color: isDone ? Colors.white : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
