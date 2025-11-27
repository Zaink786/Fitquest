import 'package:flutter/material.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  final List<Map<String, dynamic>> _workouts = [];

  void _addWorkout() {
    if (_nameController.text.isNotEmpty && _durationController.text.isNotEmpty) {
      setState(() {
        _workouts.add({
          'name': _nameController.text,
          'duration': int.parse(_durationController.text),
          'date': DateTime.now(),
        });
      });

      _nameController.clear();
      _durationController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Workout added!")),
      );
    }
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
            const Text("Log a Workout",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Duration (mins)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _addWorkout,
              child: const Text("Add Workout"),
            ),

            const SizedBox(height: 20),
            const Text("Your Workouts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _workouts.length,
                itemBuilder: (context, index) {
                  final workout = _workouts[index];
                  return Card(
                    child: ListTile(
                      title: Text(workout['name']),
                      subtitle: Text(
                        "Duration: ${workout['duration']} mins\n"
                        "Date: ${workout['date'].toString().split('.')[0]}",
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
