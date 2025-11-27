import 'package:flutter/material.dart';
import '../../models/workout_model.dart'; 

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();

  // Using the Workout model instead of Map
  final List<Workout> _workouts = [];

  void _addWorkout() {
    if (_nameController.text.isEmpty || _setsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a workout name and sets")),
      );
      return;
    }

    final sets = int.tryParse(_setsController.text);
    if (sets == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sets must be a number")),
      );
      return;
    }

    final workout = Workout(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      type: "Gym", // temporary default – can make this user-selectable later
      date: DateTime.now(),
      sets: sets,
      pointsEarned: 0, // placeholder until points logic is added
    );

    setState(() {
      _workouts.add(workout);
    });

    _nameController.clear();
    _setsController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Workout added!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Workouts")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Log a Workout",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Workout Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Sets", 
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _addWorkout,
              child: const Text("Add Workout"),
            ),

            const SizedBox(height: 20),
            const Text(
              "Your Workouts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _workouts.length,
                itemBuilder: (context, index) {
                  final workout = _workouts[index];
                  return Card(
                    child: ListTile(
                      title: Text(workout.name),
                      subtitle: Text(
                        "Sets: ${workout.sets}\n"
                        "Date: ${workout.date.toString().split('.')[0]}",
                      ),
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
}
