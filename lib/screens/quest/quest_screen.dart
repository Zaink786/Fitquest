import 'package:flutter/material.dart';
import '../../models/quest_model.dart';
import '../../services/storage_service.dart';

final _displayWorlds = questWorlds.reversed.toList();

class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  int _questPoints = 0;

  @override
  void initState() {
    super.initState();
    _questPoints = StorageService.getQuestPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2461),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D2461),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Quest',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _questPoints = StorageService.getQuestPoints());
        },
        child: const Center(
          child: Text('World map coming soon',
              style: TextStyle(color: Colors.white54)),
        ),
      ),
    );
  }
}
